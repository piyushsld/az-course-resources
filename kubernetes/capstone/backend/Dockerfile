# Use Python 3.12 slim image
FROM python:3.11-bullseye

# Set working directory
WORKDIR /app

# Add PostgreSQL repository
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
    && curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg

# Install system dependencies including PostgreSQL client, build tools, and dos2unix
RUN apt-get update && apt-get install -y \
    postgresql-client-16 \
    libpq-dev \
    gcc \
    python3-dev \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Ensure migrate.sh has Unix line endings
RUN chmod +x migrate.sh entrypoint.sh

# Expose port
EXPOSE 8000

# Command to run the application
CMD ["./entrypoint.sh"]