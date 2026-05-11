#!/bin/bash
# Weinchen Docker Build & Push Script
# Multi-stage build: React frontend + Node.js backend
# Usage: ./buildpush.sh [--no-push]

set -e  # Exit on error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKERFILE="${SCRIPT_DIR}/Dockerfile"
IMAGE_TAG="registry.example.internal/weinchen:latest"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Parse arguments
NO_PUSH=false
if [[ "$1" == "--no-push" ]]; then
    NO_PUSH=true
fi

echo -e "${BLUE}Building Weinchen Docker Image${NC}"
echo "================================"
echo "Project Dir: ${SCRIPT_DIR}"
echo "Dockerfile:  ${DOCKERFILE}"
echo "Image Tag:   ${IMAGE_TAG}"
echo ""

# Resolve version from latest git tag (sorted by version number)
BUILD_VERSION=$(git tag --sort=-v:refname 2>/dev/null | head -1)
BUILD_VERSION=${BUILD_VERSION:-0.0.0}
echo "Version:     ${BUILD_VERSION}"

# Build
echo -e "${BLUE}Building Docker image...${NC}"
if docker build -t "${IMAGE_TAG}" -f "${DOCKERFILE}" "${SCRIPT_DIR}"; then
    echo -e "${GREEN}Build successful!${NC}"
else
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi

# Push
if [ "$NO_PUSH" = false ]; then
    echo ""
    echo -e "${BLUE}Pushing to registry...${NC}"
    if docker push "${IMAGE_TAG}"; then
        echo -e "${GREEN}Push successful!${NC}"
        echo ""
        echo -e "${GREEN}Done! Image available at: ${IMAGE_TAG}${NC} [$(date '+%Y-%m-%d %H:%M:%S')]"
    else
        echo -e "${RED}Push failed!${NC}"
        exit 1
    fi
else
    echo ""
    echo -e "${BLUE}Skipping push (--no-push flag set)${NC}"
    echo -e "${GREEN}Build complete! Image: ${IMAGE_TAG}${NC}"
fi
