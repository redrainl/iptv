#!/bin/bash
# docker build --no-cache -t iptv-batch-tester:env
docker run --rm -v $(pwd):/work iptv-batch-tester:env
