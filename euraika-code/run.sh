#!/bin/bash

set -e

IMAGE_REGISTRY=${IMAGE_REGISTRY:-""}
IMAGE_TAG=${IMAGE_TAG:-"latest"}

function build() {
    echo "Building images..."
    docker compose build

    if [ -n "$IMAGE_REGISTRY" ]; then
        docker tag euraika-frontend:latest ${IMAGE_REGISTRY}/euraika-frontend:${IMAGE_TAG}
        docker tag euraika-backend:latest ${IMAGE_REGISTRY}/euraika-backend:${IMAGE_TAG}
        docker tag euraika-sandbox:latest ${IMAGE_REGISTRY}/euraika-sandbox:${IMAGE_TAG}
    fi
}

function push() {
    if [ -z "$IMAGE_REGISTRY" ]; then
        echo "Error: IMAGE_REGISTRY is not set"
        exit 1
    fi

    echo "Pushing images to ${IMAGE_REGISTRY}..."
    docker push ${IMAGE_REGISTRY}/euraika-frontend:${IMAGE_TAG}
    docker push ${IMAGE_REGISTRY}/euraika-backend:${IMAGE_TAG}
    docker push ${IMAGE_REGISTRY}/euraika-sandbox:${IMAGE_TAG}
}

case "$1" in
    build)
        build
        ;;
    push)
        push
        ;;
    *)
        echo "Usage: $0 {build|push}"
        exit 1
        ;;
esac
