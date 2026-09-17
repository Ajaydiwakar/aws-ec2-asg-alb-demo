# Dockerfile All Instructions Demo

This project demonstrates the commonly used **Dockerfile instructions**, including building an image, creating and mounting volumes, running a container, health checks, and configuring an executable entrypoint script.

---

## 1. Build the Docker Image

Build the Docker image using the following command:

```bash
docker build \
  --build-arg APP_VERSION=1.0 \
  -t docker-all-instructions:1.0 .
```

### What happens during the build?

When you run `docker build`, Docker:

1. Reads the `Dockerfile`.
2. Uses the `FROM` instruction to select the Python base image.
3. Uses `RUN` instructions to install dependencies and execute commands.
4. Uses `COPY` and `ADD` to place application files into the image.
5. Creates image layers for each Dockerfile instruction.
6. Tags the final image as:

```text
docker-all-instructions:1.0
```

You can verify the image using:

```bash
docker images
```

---

## 2. Create a Docker Volume

Create a named Docker volume:

```bash
docker volume create docker-demo-data
```

Verify the volume:

```bash
docker volume ls
```

The volume will be used to persist data outside the container's writable layer.

---

## 3. Run the Container

Run the Docker container in detached mode:

```bash
docker run -d \
  --name docker-demo \
  -p 5001:5001 \
  -v docker-demo-data:/data \
  docker-all-instructions:1.0
```

### Explanation

| Option                        | Description                                              |
| ----------------------------- | -------------------------------------------------------- |
| `-d`                          | Runs the container in detached/background mode           |
| `--name docker-demo`          | Assigns the name `docker-demo` to the container          |
| `-p 5001:5001`                | Maps host port `5001` to container port `5001`           |
| `-v docker-demo-data:/data`   | Mounts the Docker volume to `/data` inside the container |
| `docker-all-instructions:1.0` | Image used to create the container                       |

---

## 4. Test the Application

Test the application using `curl`:

```bash
curl http://localhost:5001/
```

You can also use:

```bash
curl http://localhost:5001
```

---

## 5. Check Application Health

The application provides a health endpoint:

```bash
curl http://localhost:5001/health
```

### Expected Response

```json
{
  "status": "healthy"
}
```

---

## 6. Verify the Running Container

Check the running containers:

```bash
docker ps
```

You should see the `docker-demo` container running.

Example:

```text
CONTAINER ID   IMAGE                         COMMAND                  STATUS        PORTS
2631c1b9e586   docker-all-instructions:1.0   ...                      Up ...        0.0.0.0:5001->5001/tcp
```

---

## 7. Inspect the Container Health Status

Docker's health-check information can be inspected using:

```bash
docker inspect --format='{{json .State.Health}}' docker-demo
```

This displays the health status reported by the `HEALTHCHECK` instruction in the Dockerfile.

---

# Troubleshooting

## Error: Permission Denied for Entrypoint

While running the container, you may encounter the following error:

```text
docker: Error response from daemon: failed to create task for container:
failed to create shim task: OCI runtime create failed:
runc create failed: unable to start container process:
error during container init:
exec: "/usr/local/bin/docker-entrypoint.sh": permission denied
```

For example:

```bash
docker run -d \
  --name docker-demo \
  -p 5001:5001 \
  -v docker-demo-data:/data \
  docker-all-instructions:1.0
```

Docker may initially return a container ID such as:

```text
2631c1b9e586ac6c584d94a1e4206c71ee5d484c4c6e9a0deb5c1c1b5e63e5f5
```

followed by the permission error.

---

## Why Does This Error Happen?

The Dockerfile contains:

```dockerfile
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
```

and later:

```dockerfile
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
```

The `ENTRYPOINT` instruction tells Docker to execute:

```text
/usr/local/bin/docker-entrypoint.sh
```

However, the script must have **execute permission**.

If the script does not have executable permissions, Docker cannot execute it and produces:

```text
permission denied
```

---

## Important: `chown` Does Not Add Execute Permission

Your Dockerfile may contain something similar to:

```dockerfile
RUN useradd --create-home --shell /bin/sh appuser \
    && mkdir -p /data \
    && printf 'Created during image build\n' > /data/build-info.txt \
    && chown -R appuser:appuser /app /data /usr/local/bin/docker-entrypoint.sh
```

The `chown` command changes the **ownership** of the file.

It does **not** automatically make the file executable.

For example:

```bash
chown appuser:appuser docker-entrypoint.sh
```

changes ownership, while:

```bash
chmod +x docker-entrypoint.sh
```

adds execute permission.

Therefore, both ownership and permissions are separate concepts.

---

# Fix 1: Use `chmod +x`

Open the Dockerfile:

```bash
vi Dockerfile
```

Find:

```dockerfile
COPY app.py ./
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
```

Add a `RUN chmod` instruction:

```dockerfile
COPY app.py ./
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh
```

The important instruction is:

```dockerfile
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
```

This gives the entrypoint script executable permission.

---

# Fix 2: Use `COPY --chmod`

A cleaner approach is to set the permissions directly when copying the file:

```dockerfile
COPY --chmod=755 docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
```

This copies the script and sets its permissions to:

```text
755
```

which means:

```text
Owner:  read + write + execute
Group:  read + execute
Others: read + execute
```

For example:

```dockerfile
COPY app.py ./
COPY --chmod=755 docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
```

This avoids needing a separate `RUN chmod` instruction.

---

# Rebuild the Image After the Fix

After modifying the Dockerfile, rebuild the image:

```bash
docker build \
  --build-arg APP_VERSION=1.0 \
  -t docker-all-instructions:1.0 . --no-cache
```

Then run the container again:

```bash
docker run -d \
  --name docker-demo \
  -p 5001:5001 \
  -v docker-demo-data:/data \
  docker-all-instructions:1.0
```

Verify:

```bash
docker ps
```

Test the application:

```bash
curl http://localhost:5001/
```

Test the health endpoint:

```bash
curl http://localhost:5001/health
```

---

# Complete Quick-Start

For a quick demonstration, use the following sequence:

### 1. Build

```bash
docker build \
  --build-arg APP_VERSION=1.0 \
  -t docker-all-instructions:1.0 .
```

### 2. Create Volume

```bash
docker volume create docker-demo-data
```

### 3. Run

```bash
docker run -d \
  --name docker-demo \
  -p 5001:5001 \
  -v docker-demo-data:/data \
  docker-all-instructions:1.0
```

### 4. Test

```bash
curl http://localhost:5001/
```

### 5. Health Check

```bash
curl http://localhost:5001/health
```

### 6. Check Container

```bash
docker ps
```

### 7. Inspect Health

```bash
docker inspect --format='{{json .State.Health}}' docker-demo
```

---

# Stop and Remove the Container

Stop the container:

```bash
docker stop docker-demo
```

Remove the container:

```bash
docker rm docker-demo
```

The named volume is **not automatically removed** when the container is deleted.

To verify the volume still exists:

```bash
docker volume ls
```

If you want to remove it as well:

```bash
docker volume rm docker-demo-data
```

---

## Dockerfile Permission Concept

The key concept demonstrated by this troubleshooting exercise is:

```text
COPY
  │
  ▼
docker-entrypoint.sh
  │
  ▼
File exists inside image
  │
  ▼
Does it have execute permission?
  │
  ├── NO ──► permission denied
  │
  └── YES ─► ENTRYPOINT can execute
```

Therefore, when using a shell script as an `ENTRYPOINT`, make sure it is executable:

```dockerfile
COPY --chmod=755 docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
```

or:

```dockerfile
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
```
