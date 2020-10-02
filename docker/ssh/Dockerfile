FROM wordpress:latest

# Install OpenSSH daemon
RUN apt-get update && apt-get install -y openssh-server && mkdir -p /var/run/sshd

# Copying custom Docker entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
