FROM wordpress:latest

# Setup custom entrypoint script
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
CMD ["apache2-foreground"]

# Add custom PHP configuration to wordpress image
COPY ./config/wordpress.ini /usr/local/etc/php/conf.d/wordpress.ini
