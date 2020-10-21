FROM certbot/certbot

COPY entrypoint.sh /usr/bin/
COPY run-certbot.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh /usr/bin/run-certbot.sh
ENTRYPOINT ["entrypoint.sh"]
