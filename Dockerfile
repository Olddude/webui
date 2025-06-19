# Build stage
FROM node:20.11.1-alpine AS build
ARG WEBUI_AGENT_BACKEND_BASE_URL=http://host.docker.internal:3004
ENV WEBUI_AGENT_BACKEND_BASE_URL=$WEBUI_AGENT_BACKEND_BASE_URL

WORKDIR /app
COPY package*.json ./
RUN npm install --frozen-lockfile --omit=dev
COPY . .
RUN npm run build

# Runtime stage
FROM nginx:alpine3.21-slim as runtime
ENV WEBUI_AGENT_BACKEND_BASE_URL=$WEBUI_AGENT_BACKEND_BASE_URL

RUN apk add --no-cache \
    gzip \
    tree \
    bash \
    && rm -rf /var/cache/apk/*

RUN rm -rf /usr/share/nginx/html/*
COPY --from=build /app/dist/demo-conversation.json /usr/share/nginx/html/demo-conversation.json
COPY --from=build /app/dist/index.html /usr/share/nginx/html/index.html
COPY --from=build /app/dist/index.html.gz /usr/share/nginx/html/index.html.gz
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80
LABEL org.opencontainers.image.source https://github.com/olddude/webui
CMD ["/entrypoint.sh"]
