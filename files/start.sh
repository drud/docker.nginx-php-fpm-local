#!/bin/bash

# Display PHP errors or not
if [[ "$ERRORS" != "1" ]] ; then
 sudo echo php_flag[display_errors] = off >> /etc/php/7.0/fpm/php-fpm.conf
else
 sudo echo php_flag[display_errors] = on >> /etc/php/7.0/fpm/php-fpm.conf
fi

sudo chown -R nginx:nginx /var/www/html/docroot

sudo /usr/bin/supervisord -c /etc/supervisord.conf

echo 'Server started'
sudo tail -f /var/log/nginx/error.log
