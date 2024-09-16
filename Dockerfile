FROM python:3.11-slim
WORKDIR /app

RUN apt-get update && apt-get install -y cron git vim && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Clone ComfyUI repository
RUN git clone https://github.com/comfyanonymous/ComfyUI.git

# Install ComfyUI dependencies
WORKDIR /app/ComfyUI
RUN pip install --no-cache-dir -r requirements.txt

# Return to main app directory
WORKDIR /app

COPY requirements_dev.txt .
RUN pip install --no-cache-dir -r requirements_dev.txt

COPY workflow.sh .
COPY utils ./utils
COPY workflow ./workflow
RUN chmod +x workflow.sh

# Copy crontab file and set up the cron job
COPY crontab /etc/cron.d/my-crontab
RUN chmod 0644 /etc/cron.d/my-crontab && \
    crontab /etc/cron.d/my-crontab

# Install Chrome and dependencies for Selenium
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    vim \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Firefox and GeckoDriver
RUN apt-get update && apt-get install -y \
    firefox-esr \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*4

# Install GeckoDriver
RUN wget https://github.com/mozilla/geckodriver/releases/download/v0.30.0/geckodriver-v0.30.0-linux64.tar.gz \
    && tar -xvzf geckodriver-v0.30.0-linux64.tar.gz \
    && chmod +x geckodriver \
    && mv geckodriver /usr/local/bin/ \
    && rm geckodriver-v0.30.0-linux64.tar.gz

# Set environment variables
ENV PROJECT_PATH=/app
ENV MODELS_PATH=/app/models
ENV COMFY_PATH=/app/ComfyUI

# Copy the rest of your application
COPY . .

# Start cron in the foreground
CMD ["cron", "-f"]