FROM node:18-alpine
WORKDIR /app
COPY *.json ./
RUN npm ci
COPY *.js ./
ENTRYPOINT ["node", "main.js"]