FROM n8nio/n8n:latest

# Create necessary directories
USER root
RUN mkdir -p /home/node/.n8n/workflows /home/node/.n8n/credentials && \
    chown -R node:node /home/node/.n8n

# Switch back to node user
USER node

# Expose n8n port
EXPOSE 5678
