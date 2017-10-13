#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

HOST_PORT="1081"
CONTAINER_PORT="80"

docker stop web-local-test || true
docker rm web-local-test || true

echo "checking tool versions"
docker run -it `awk '{print $1}' .docker_image` php --version | grep "PHP 7"
docker run -it `awk '{print $1}' .docker_image` drush --version
docker run -it `awk '{print $1}' .docker_image` wp --version

echo "starting container for tests"
docker run -p $HOST_PORT:$CONTAINER_PORT -e "DOCROOT=docroot" -d --name web-local-test -d `awk '{print $1}' .docker_image`
CONTAINER_NAME=web-local-test ./test/containercheck.sh

echo "testing php and email"
curl --fail localhost:$HOST_PORT/test/phptest.php
curl -s localhost:$HOST_PORT/test/test-email.php | grep "Test email sent"
docker stop web-local-test && docker rm web-local-test

echo "testing use of custom nginx config"
docker run -p $HOST_PORT:$CONTAINER_PORT -e "DOCROOT=potato" -v `pwd`/test/test-custom.conf:/var/www/html/.ddev/nginx-site.conf -d --name web-local-test -d `awk '{print $1}' .docker_image`
docker exec -it web-local-test cat /etc/nginx/sites-enabled/nginx-site.conf | grep "docroot is /var/www/html/potato in custom conf"
docker stop web-local-test && docker rm web-local-test
