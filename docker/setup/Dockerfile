FROM ubuntu:latest

RUN apt-get update && apt-get install -y mysql-client

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
