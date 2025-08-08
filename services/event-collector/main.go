package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gorilla/mux"
)

type EventPayload struct {
	Service   string                 `json:"service"`
	Instance  string                 `json:"instance"`
	Action    string                 `json:"action"`
	Title     string                 `json:"title"`
	Quality   string                 `json:"quality,omitempty"`
	SizeBytes int64                  `json:"size_bytes,omitempty"`
	Timestamp string                 `json:"timestamp"`
	Details   map[string]interface{} `json:"details,omitempty"`
}

type Config struct {
	Bind     string
	Token    string
	LogDir   string
	LogLevel string
}

func loadConfig() *Config {
	return &Config{
		Bind:     getEnv("EVENT_COLLECTOR_BIND", "0.0.0.0:8088"),
		Token:    getEnv("EVENT_COLLECTOR_TOKEN", ""),
		LogDir:   getEnv("EVENT_COLLECTOR_LOG_DIR", "/var/log/event-collector"),
		LogLevel: getEnv("EVENT_COLLECTOR_LOG_LEVEL", "INFO"),
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func authMiddleware(token string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if token == "" {
				http.Error(w, "Server configuration error", http.StatusInternalServerError)
				return
			}

			authHeader := r.Header.Get("X-Auth-Token")
			if authHeader != token {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}

func webhookHandler(config *Config) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		vars := mux.Vars(r)
		service := vars["service"]
		instance := vars["instance"]

		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		body, err := io.ReadAll(r.Body)
		if err != nil {
			log.Printf("Error reading request body: %v", err)
			http.Error(w, "Bad request", http.StatusBadRequest)
			return
		}

		var payload map[string]interface{}
		if err := json.Unmarshal(body, &payload); err != nil {
			log.Printf("Error parsing JSON: %v", err)
			http.Error(w, "Invalid JSON", http.StatusBadRequest)
			return
		}

		// Enrich payload with service and instance info
		event := EventPayload{
			Service:  service,
			Instance: instance,
		}

		// Extract standard fields
		if action, ok := payload["action"].(string); ok {
			event.Action = action
		}
		if title, ok := payload["title"].(string); ok {
			event.Title = title
		}
		if quality, ok := payload["quality"].(string); ok {
			event.Quality = quality
		}
		if sizeBytes, ok := payload["size_bytes"].(float64); ok {
			event.SizeBytes = int64(sizeBytes)
		}
		if timestamp, ok := payload["timestamp"].(string); ok {
			event.Timestamp = timestamp
		} else {
			event.Timestamp = time.Now().Format(time.RFC3339)
		}

		// Store remaining fields in details
		event.Details = make(map[string]interface{})
		for k, v := range payload {
			if k != "action" && k != "title" && k != "quality" && k != "size_bytes" && k != "timestamp" {
				event.Details[k] = v
			}
		}

		// Write to JSONL file
		if err := writeEventToFile(config, &event); err != nil {
			log.Printf("Error writing event to file: %v", err)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
			return
		}

		log.Printf("Event received: %s/%s - %s", service, instance, event.Action)

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusAccepted)
		json.NewEncoder(w).Encode(map[string]string{"status": "accepted"})
	}
}

func writeEventToFile(config *Config, event *EventPayload) error {
	// Ensure log directory exists
	if err := os.MkdirAll(config.LogDir, 0755); err != nil {
		return fmt.Errorf("failed to create log directory: %w", err)
	}

	// Use daily rotation
	filename := fmt.Sprintf("events-%s.jsonl", time.Now().Format("2006-01-02"))
	filepath := filepath.Join(config.LogDir, filename)

	file, err := os.OpenFile(filepath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		return fmt.Errorf("failed to open log file: %w", err)
	}
	defer file.Close()

	// Write as JSONL
	eventJSON, err := json.Marshal(event)
	if err != nil {
		return fmt.Errorf("failed to marshal event: %w", err)
	}

	if _, err := file.Write(append(eventJSON, '\n')); err != nil {
		return fmt.Errorf("failed to write to log file: %w", err)
	}

	return nil
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status":    "healthy",
		"timestamp": time.Now().Format(time.RFC3339),
	})
}

func main() {
	config := loadConfig()

	if config.Token == "" {
		log.Fatal("EVENT_COLLECTOR_TOKEN environment variable is required")
	}

	r := mux.NewRouter()

	// Health check endpoint (no auth required)
	r.HandleFunc("/health", healthHandler).Methods("GET")

	// Webhook endpoints with auth
	webhookRoutes := r.PathPrefix("/webhook").Subrouter()
	webhookRoutes.Use(authMiddleware(config.Token))
	webhookRoutes.HandleFunc("/{service}/{instance}", webhookHandler(config)).Methods("POST")

	log.Printf("Event Collector starting on %s", config.Bind)
	log.Printf("Log directory: %s", config.LogDir)

	if err := http.ListenAndServe(config.Bind, r); err != nil {
		log.Fatal("Server failed to start:", err)
	}
}
