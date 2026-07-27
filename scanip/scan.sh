#!/bin/bash
> alive.txt
docker rm -f scanner
docker run -d \
  --name scanner \
  --net=host \
  --ulimit nofile=65535:65535 \
  -v $(pwd):/app \
  -w /app \
  python:3.11-slim bash -c "apt install -y coreutils && python3 scan.py"
docker logs -f scanner
