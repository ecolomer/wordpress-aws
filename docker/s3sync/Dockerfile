FROM amazon/aws-cli

COPY entrypoint.sh sync-to-s3.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh /usr/bin/sync-to-s3.sh
ENTRYPOINT ["entrypoint.sh"]
