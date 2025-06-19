FROM nginx:alpine
WORKDIR /opt/webui
RUN apk add --no-cache \
    bash \
    ca-certificates \
    tree \
    && adduser -D -s /bin/false webui
RUN rm -rf /usr/share/nginx/html/*
COPY dist/ ./dist/
COPY scripts/run.sh ./scripts/run.sh
COPY nginx.conf /etc/nginx/nginx.conf
RUN chown -R webui:webui /opt/webui
USER webui
EXPOSE 80
ENTRYPOINT ["/bin/bash"]
CMD ["./scripts/run.sh"]
