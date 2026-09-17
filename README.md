# Dockerfile All Instructions Demo

Build:
```bash
docker build --build-arg APP_VERSION=1.0 -t docker-all-instructions:1.0 .
```

Run:
```bash
docker volume create docker-demo-data
docker run -d --name docker-demo -p 5001:5001 -v docker-demo-data:/data docker-all-instructions:1.0
```

Test:
```bash
curl http://localhost:5001/
curl http://localhost:5001/health
docker ps
docker inspect --format='{{json .State.Health}}' docker-demo
```

Stop and remove:
```bash
docker stop docker-demo
docker rm docker-demo
```
