FROM node:22.22.0-alpine
WORKDIR /app
ENV NODE_ENV=production PORT=8080 SERVICE_NAME=cs554-midterm READINESS_BLOCK_FILE=/tmp/midterm-not-ready
COPY --chown=node:node package.json ./
COPY --chown=node:node src/ ./src/
USER node
EXPOSE 8080
CMD ["node", "src/server.js"]
