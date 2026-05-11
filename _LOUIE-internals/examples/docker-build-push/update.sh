#!/bin/bash
# Weinchen - Docker Update Script
# Run this on the production server to update the container
# Usage: ./update.sh

set -e

CONTAINER_NAME="weinchen"
IMAGE_TAG="registry.example.internal/weinchen:latest"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Updating Weinchen${NC}"
echo "================================"

# 1) Stop and remove container
echo -e "${BLUE}Stopping container...${NC}"
sudo docker stop ${CONTAINER_NAME} || true
sudo docker rm ${CONTAINER_NAME} || true

# 2) Remove old image
echo -e "${BLUE}Removing old image...${NC}"
sudo docker image rm ${IMAGE_TAG} || true

# 3) Pull new image
echo -e "${BLUE}Pulling new image...${NC}"
sudo docker pull ${IMAGE_TAG}

# 4) Start container
echo -e "${BLUE}Starting container...${NC}"
sudo docker run -d --name ${CONTAINER_NAME} \
  --restart unless-stopped \
  --user 1027:100 \
  -p 2650:3000 \
  -e NODE_ENV=production \
  -e TZ="Europe/Berlin" \
  -e DATABASE_HOST=db.example.internal \
  -e DATABASE_PORT=3306 \
  -e DATABASE_NAME=weinchen \
  -e DATABASE_USER=weinchen_user \
  -e DATABASE_PASSWORD=REDACTED_DO_NOT_USE_THIS_PATTERN \
  -e PORT=3000 \
  ${IMAGE_TAG}

echo ""
echo -e "${GREEN}Done! [$(date "+%Y-%m-%d %H:%M:%S")]${NC}"
echo -e "${GREEN}Container running on port 2650${NC}"
