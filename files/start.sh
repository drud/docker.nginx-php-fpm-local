#!/bin/bash

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
