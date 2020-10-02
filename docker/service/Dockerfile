FROM wordpress:latest

# Setup custom entrypoint script
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
CMD ["apache2-foreground"]

# Add custom PHP configuration to wordpress image
COPY ./config/wordpress.ini /usr/local/etc/php/conf.d/wordpress.ini

# Add custom Apache configuration to wordpress image
COPY ./config/apache.conf /etc/apache2/custom-apache2.conf
RUN a2enmod headers && /bin/echo "Include /etc/apache2/custom-apache2.conf" >> /etc/apache2/apache2.conf