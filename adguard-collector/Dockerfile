FROM python:3.11-alpine

# Install required packages
RUN pip install requests

# Create app directory
WORKDIR /app

# Copy application files
COPY collector.py /app/

# Create data directory for state persistence
RUN mkdir -p /data

# Set environment variables defaults
ENV ADGUARD_HOST=192.168.10.1
ENV ADGUARD_PORT=3000
ENV ADGUARD_USERNAME=admin
ENV ADGUARD_PASSWORD=""
ENV SYSLOG_HOST=192.168.10.10
ENV SYSLOG_PORT=1514
ENV POLL_INTERVAL=30
ENV BATCH_SIZE=100

# Run the collector
CMD ["python", "collector.py"]