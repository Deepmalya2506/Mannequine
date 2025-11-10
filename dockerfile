# Raspberry Pi 4B Voice Assistant - Dockerfile
# Base image: Python 3.11 on Debian Bookworm (ARM64 compatible)
FROM python:3.11-slim-bookworm

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive \
    PULSE_SERVER=unix:/run/user/1000/pulse/native

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Audio dependencies
    portaudio19-dev \
    python3-pyaudio \
    alsa-utils \
    pulseaudio \
    pulseaudio-utils \
    # Speech synthesis (espeak for pyttsx3)
    espeak \
    espeak-ng \
    libespeak-dev \
    libespeak-ng1 \
    # Build tools
    gcc \
    g++ \
    make \
    # Utilities
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements file first (for better caching)
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY main_pi.py .
COPY .env .

# Create necessary directories
RUN mkdir -p /root/.config/pulse

# Expose WebSocket port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health')" || exit 1

# Run the application
CMD ["python", "-u", "main_pi.py"]