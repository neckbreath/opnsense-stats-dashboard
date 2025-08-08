#!/usr/bin/env python3
"""
AdGuard Home API Query Log Collector
Fetches query logs from AdGuard Home API and forwards to syslog
"""

import json
import time
import socket
import logging
import requests
from datetime import datetime, timezone
from typing import Dict, List, Optional
import os
from requests.auth import HTTPBasicAuth


class AdGuardCollector:
    def __init__(self):
        # Configuration from environment variables
        self.adguard_host = os.getenv('ADGUARD_HOST', '192.168.10.1')
        self.adguard_port = os.getenv('ADGUARD_PORT', '3000')
        self.adguard_username = os.getenv('ADGUARD_USERNAME', 'admin')
        self.adguard_password = os.getenv('ADGUARD_PASSWORD', '')
        
        # Syslog configuration
        self.syslog_host = os.getenv('SYSLOG_HOST', '192.168.10.10')
        self.syslog_port = int(os.getenv('SYSLOG_PORT', '1514'))
        
        # Collection settings
        self.poll_interval = int(os.getenv('POLL_INTERVAL', '30'))  # seconds
        self.batch_size = int(os.getenv('BATCH_SIZE', '100'))
        
        # API endpoint
        self.api_url = f"http://{self.adguard_host}:{self.adguard_port}/control/querylog"
        
        # State management
        self.last_timestamp = None
        self.state_file = '/data/collector_state.json'
        
        # Setup logging
        logging.basicConfig(level=logging.INFO, 
                          format='%(asctime)s - %(levelname)s - %(message)s')
        self.logger = logging.getLogger(__name__)
        
        # Load state
        self.load_state()

    def load_state(self):
        """Load the last processed timestamp from state file"""
        try:
            if os.path.exists(self.state_file):
                with open(self.state_file, 'r') as f:
                    state = json.load(f)
                    self.last_timestamp = state.get('last_timestamp')
                    self.logger.info(f"Loaded state: last_timestamp={self.last_timestamp}")
        except Exception as e:
            self.logger.error(f"Failed to load state: {e}")

    def save_state(self):
        """Save the current state to file"""
        try:
            os.makedirs(os.path.dirname(self.state_file), exist_ok=True)
            with open(self.state_file, 'w') as f:
                json.dump({'last_timestamp': self.last_timestamp}, f)
        except Exception as e:
            self.logger.error(f"Failed to save state: {e}")

    def fetch_query_logs(self) -> List[Dict]:
        """Fetch query logs from AdGuard Home API"""
        try:
            params = {'limit': self.batch_size}
            if self.last_timestamp:
                params['older_than'] = self.last_timestamp
                
            auth = HTTPBasicAuth(self.adguard_username, self.adguard_password)
            response = requests.get(self.api_url, params=params, auth=auth, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            query_logs = data.get('data', [])
            
            self.logger.info(f"Fetched {len(query_logs)} query log entries")
            return query_logs
            
        except requests.exceptions.RequestException as e:
            self.logger.error(f"Failed to fetch query logs: {e}")
            return []

    def format_syslog_message(self, query_log: Dict) -> str:
        """Format a query log entry as syslog message for AdGuard"""
        try:
            # Extract key fields from API response
            timestamp = query_log.get('time', '')
            client_ip = query_log.get('client', '')
            question = query_log.get('question', {})
            domain = question.get('name', '')
            query_type = question.get('type', '')
            
            # Determine status
            answer = query_log.get('answer', [])
            filtered_rule = query_log.get('reason', '')
            upstream = query_log.get('upstream', '')
            elapsed_ms = query_log.get('elapsedMs', 0)
            
            # Determine status based on response
            if query_log.get('reason') in ['FilteredBlockList', 'FilteredSafetyNet']:
                status = 'blocked'
            elif query_log.get('reason') == 'NotFiltered':
                status = 'allowed'
            else:
                status = 'cached'
            
            # Format similar to AdGuardHome syslog format that our Promtail expects
            message = (f"query {domain} {query_type} from client {client_ip} "
                      f"{status} {elapsed_ms}ms upstream {upstream}")
            
            # Add rule info if blocked
            if filtered_rule and status == 'blocked':
                message += f" rule {filtered_rule}"
            
            return message
            
        except Exception as e:
            self.logger.error(f"Failed to format syslog message: {e}")
            return f"query parsing_error from client unknown allowed 0ms"

    def send_to_syslog(self, message: str):
        """Send formatted message to syslog server"""
        try:
            # Create syslog format: <priority>timestamp hostname program: message
            timestamp = datetime.now(timezone.utc).strftime('%b %d %H:%M:%S')
            hostname = 'adguard-collector'
            program = 'AdGuardHome'
            priority = 16  # local0.info
            
            syslog_msg = f"<{priority}>{timestamp} {hostname} {program}: {message}"
            
            # Send UDP packet to syslog server
            sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            sock.sendto(syslog_msg.encode('utf-8'), (self.syslog_host, self.syslog_port))
            sock.close()
            
        except Exception as e:
            self.logger.error(f"Failed to send to syslog: {e}")

    def process_query_logs(self, query_logs: List[Dict]):
        """Process and forward query logs to syslog"""
        if not query_logs:
            return
            
        # Sort by timestamp to process in chronological order
        query_logs.sort(key=lambda x: x.get('time', ''))
        
        sent_count = 0
        for query_log in query_logs:
            try:
                message = self.format_syslog_message(query_log)
                self.send_to_syslog(message)
                sent_count += 1
                
                # Update last processed timestamp
                if 'time' in query_log:
                    self.last_timestamp = query_log['time']
                    
            except Exception as e:
                self.logger.error(f"Failed to process query log: {e}")
                continue
        
        self.logger.info(f"Sent {sent_count} query logs to syslog")
        
        # Save state after successful processing
        if sent_count > 0:
            self.save_state()

    def run(self):
        """Main collection loop"""
        self.logger.info("Starting AdGuard Home API Collector")
        self.logger.info(f"AdGuard: {self.adguard_host}:{self.adguard_port}")
        self.logger.info(f"Syslog: {self.syslog_host}:{self.syslog_port}")
        self.logger.info(f"Poll interval: {self.poll_interval} seconds")
        
        while True:
            try:
                # Fetch new query logs
                query_logs = self.fetch_query_logs()
                
                # Process and forward to syslog
                self.process_query_logs(query_logs)
                
                # Wait for next poll
                time.sleep(self.poll_interval)
                
            except KeyboardInterrupt:
                self.logger.info("Shutting down collector")
                break
            except Exception as e:
                self.logger.error(f"Unexpected error in main loop: {e}")
                time.sleep(self.poll_interval)


if __name__ == "__main__":
    collector = AdGuardCollector()
    collector.run()