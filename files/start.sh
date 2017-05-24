#!/bin/bash

# Change nginx to UID/GID of the docker user
if [ -n "$UID" ] ; then
    usermod -u $UID nginx
fi
if [ -n "$GID" ] ; then
    groupmod -g $GID nginx
fi

# Display PHP errors or not
if [[ "$ERRORS" != "1" ]] ; then
 echo php_flag[display_errors] = off >> /etc/php/7.0/fpm/php-fpm.conf
else
 echo php_flag[display_errors] = on >> /etc/php/7.0/fpm/php-fpm.conf
fi

/usr/bin/supervisord -c /etc/supervisord.conf

echo 'Server started'
tail -f /var/log/nginx/error.log
