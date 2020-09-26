FROM alpine:latest

RUN apk update && apk add bash && apk add mysql-client && rm -f /var/cache/apk/*

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
