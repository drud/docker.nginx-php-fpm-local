#!/bin/bash

# Update full path NGINX_DOCROOT if DOCROOT env is provided
if [ -n "$DOCROOT" ] ; then
    export NGINX_DOCROOT="/var/www/html/$DOCROOT"
fi

if [ -f /var/www/html/.ddev/nginx-site.conf ] ; then
    export NGINX_SITE_TEMPLATE=/var/www/html/.ddev/nginx-site.conf
fi

# Substitute values of environment variables in nginx configuration
envsubst "$NGINX_SITE_VARS" < "$NGINX_SITE_TEMPLATE" > /etc/nginx/sites-available/nginx-site.conf

# Change nginx to UID/GID of the docker user
if [ -n "$DDEV_UID" ] ; then
    usermod -u $DDEV_UID nginx
fi
if [ -n "$DDEV_GID" ] ; then
    groupmod -g $DDEV_GID nginx
fi
chown -R nginx:nginx /var/log/nginx

# Display PHP errors or not
if [[ "$ERRORS" != "1" ]] ; then
 echo php_flag[display_errors] = off >> /etc/php/7.0/fpm/php-fpm.conf
else
 echo php_flag[display_errors] = on >> /etc/php/7.0/fpm/php-fpm.conf
fi

/usr/bin/supervisord -c /etc/supervisord.conf

echo 'Server started'
tail -f /var/log/nginx/error.log
