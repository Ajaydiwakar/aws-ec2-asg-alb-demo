# 1. FROM - specifies the base image
FROM python:3.12-slim

# 2. LABEL - adds image metadata
LABEL org.opencontainers.image.title="Dockerfile All Instructions Demo" \
      org.opencontainers.image.description="Flask app demonstrating 17 Dockerfile instructions" \
      org.opencontainers.image.version="1.0"

# 3. ARG - build-time variable
ARG APP_VERSION=1.0

# 4. ENV - runtime environment variables
ENV APP_NAME=docker-instructions-demo \
    APP_ENV=training \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# 5. SHELL - changes shell used by shell-form RUN/CMD instructions
SHELL ["/bin/sh", "-c"]

# 6. WORKDIR - sets the working directory
WORKDIR /app

# 7. RUN - executes commands during image build
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    && python -m pip install --no-cache-dir --upgrade pip

# 8. COPY - copies files from build context into image
COPY requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt

COPY app.py ./
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# 9. ADD - copies files and supports additional features such as local tar extraction
ADD welcome.txt /app/welcome.txt

# 10. EXPOSE - documents the intended container port
EXPOSE 5001

# 11. VOLUME - declares a mount point for persistent/runtime data
VOLUME ["/data"]

# Create a non-root user and prepare the volume directory
RUN useradd --create-home --shell /bin/sh appuser \
    && mkdir -p /data \
    && printf 'Created during image build\n' > /data/build-info.txt \
    && chown -R appuser:appuser /app /data /usr/local/bin/docker-entrypoint.sh

# 12. USER - commands and application run as this user
USER appuser

# 13. HEALTHCHECK - checks whether the application is healthy
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl --fail http://127.0.0.1:5001/health || exit 1

# 14. STOPSIGNAL - tells Docker which signal to send when stopping
STOPSIGNAL SIGTERM

# 15. ENTRYPOINT - defines the container's main executable
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# 16. CMD - default arguments passed to ENTRYPOINT
CMD ["python", "app.py"]
