#!/bin/bash
set -x
set -o errexit nounset pipefail

# Update full path NGINX_DOCROOT if DOCROOT env is provided
if [ -n "$DOCROOT" ] ; then
    export NGINX_DOCROOT="/var/www/html/$DOCROOT"
fi

if [ -f /var/www/html/.ddev/nginx-site.conf ] ; then
    export NGINX_SITE_TEMPLATE=/var/www/html/.ddev/nginx-site.conf
fi

# Update the default PHP and FPM versions a DDEV_PHP_VERSION like '5.6' or '7.0' is provided
# Otherwise it will use the default version configured in the Dockerfile
if [ -n "$DDEV_PHP_VERSION" ] ; then
	update-alternatives --set php /usr/bin/php${DDEV_PHP_VERSION}
	ln -sf /usr/sbin/php-fpm${DDEV_PHP_VERSION} /usr/sbin/php-fpm
	export PHP_INI=/etc/php/${DDEV_PHP_VERSION}/fpm/php.ini
fi

# Substitute values of environment variables in nginx configuration
envsubst "$NGINX_SITE_VARS" < "$NGINX_SITE_TEMPLATE" > /etc/nginx/sites-enabled/nginx-site.conf

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
 echo php_flag[display_errors] = off >> /etc/php/7.1/fpm/php-fpm.conf
else
 echo php_flag[display_errors] = on >> /etc/php/7.1/fpm/php-fpm.conf
fi

/usr/bin/supervisord -c /etc/supervisord.conf

echo 'Server started'
tail -f /var/log/nginx/error.log
