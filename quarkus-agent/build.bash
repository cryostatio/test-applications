#!/usr/bin/env bash

./mvnw -DskipTests clean package
podman build -t quay.io/redhat-java-monitoring/quarkus-cryostat-agent:latest -f src/main/docker/Dockerfile.jvm .
podman image prune -f
