FROM python:3.11-slim

# Setup working directory
WORKDIR /app

# Install system dependencies for PostgreSQL
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copy dependencies file
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

# Create user to run the app
RUN useradd --create-home --shell /bin/bash app \
    && chown -R app:app /app

# Switch to user app
USER app

# Open port 5000
EXPOSE 5000

# Command to run the app
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:app"]
