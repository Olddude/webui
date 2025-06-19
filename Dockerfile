FROM nginx:alpine
RUN apk add --no-cache \
    bash \
    ca-certificates
RUN rm -rf /usr/share/nginx/html/*
COPY dist/index.html /usr/share/nginx/html/index.html
COPY config/nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
