# Stage 1: Build shared
FROM node:20-alpine AS shared-build
WORKDIR /app/shared
COPY shared/package*.json ./
RUN npm ci
COPY shared/ ./
RUN npm run build

# Stage 2: Build client
FROM node:20-alpine AS client-build
WORKDIR /app
COPY shared/package*.json ./shared/
COPY client/package*.json ./client/
WORKDIR /app/shared
RUN npm ci
WORKDIR /app/client
RUN npm ci
WORKDIR /app
COPY shared/ ./shared/
COPY client/ ./client/
COPY --from=shared-build /app/shared/dist ./shared/dist
WORKDIR /app/client
RUN npm run build

# Stage 3: Build server
FROM node:20-alpine AS server-build
WORKDIR /app
COPY shared/package*.json ./shared/
COPY server/package*.json ./server/
WORKDIR /app/shared
RUN npm ci
WORKDIR /app/server
RUN npm ci
WORKDIR /app
COPY shared/ ./shared/
COPY server/ ./server/
COPY --from=shared-build /app/shared/dist ./shared/dist
WORKDIR /app/server
RUN npm run build

# Stage 4: Production
FROM node:20-alpine AS production
WORKDIR /app

COPY shared/package*.json ./shared/
COPY server/package*.json ./server/
WORKDIR /app/shared
RUN npm ci --omit=dev
WORKDIR /app/server
RUN npm ci --omit=dev

WORKDIR /app
COPY --from=shared-build /app/shared/dist ./shared/dist
COPY --from=server-build /app/server/dist ./server/dist
COPY --from=server-build /app/server/drizzle ./server/drizzle
COPY --from=client-build /app/client/dist ./client/dist

ENV NODE_ENV=production
ENV PORT=3000
ENV CLIENT_DIST_PATH=/app/client/dist
EXPOSE 3000

WORKDIR /app/server
CMD ["node", "dist/index.js"]
