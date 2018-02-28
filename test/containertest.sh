#!/bin/bash

set -x

set -o errexit
set -o pipefail
set -o nounset

HOST_PORT="1081"
CONTAINER_PORT="80"
# Exported so that containercheck.sh will get $CONTAINER_NAME
export CONTAINER_NAME=web-local-test
DOCKER_IMAGE=$(awk '{print $1}' .docker_image)

function cleanup {
	echo "Removing $CONTAINER_NAME"
	docker rm -f $CONTAINER_NAME 2>/dev/null || true
}
trap cleanup EXIT

cleanup

for v in 5.6 7.0 7.1 7.2; do
	echo "starting container for tests on php$v"
	CONTAINER=$(docker run -p $HOST_PORT:$CONTAINER_PORT -e "DOCROOT=docroot" -e "DDEV_PHP_VERSION=$v" -d --name $CONTAINER_NAME -d $DOCKER_IMAGE)
	./test/containercheck.sh
	curl --fail localhost:$HOST_PORT/test/phptest.php
	curl -s localhost:$HOST_PORT/test/test-email.php | grep "Test email sent"
	docker exec -it $CONTAINER php --version | grep "PHP $v"
	docker exec -it $CONTAINER drush --version
	docker exec -it $CONTAINER wp --version

	echo "testing error states for php$v"
	# These are just the standard nginx 403 and 404 pages
	curl localhost:$HOST_PORT/ | grep "403 Forbidden"
	curl localhost:$HOST_PORT/asdf | grep "404 Not Found"
	# We're just checking the error code here - there's not much more we can do in
	# this case because the container is *NOT* intercepting 50x errors.
	curl -w "%{http_code}" localhost:$HOST_PORT/test/500.php | grep 500
	# 400 and 401 errors are intercepted by the same page.
	curl localhost:$HOST_PORT/test/400.php | grep "ddev web container.*400"
	curl localhost:$HOST_PORT/test/401.php | grep "ddev web container.*401"

	echo "testing php and email for php$v"
	curl --fail localhost:$HOST_PORT/test/phptest.php
	curl -s localhost:$HOST_PORT/test/test-email.php | grep "Test email sent"

	docker rm -f $CONTAINER
done

# Run various project_types and check behavior.
for project_type in drupal6 drupal7 drupal8 typo3 backdrop wordpress default; do
	PHP_VERSION="7.1"

	if [ "$project_type" == "drupal6" ]; then
	  PHP_VERSION="5.6"
	fi
	CONTAINER=$(docker run -p $HOST_PORT:$CONTAINER_PORT -e "DOCROOT=docroot" -e "DDEV_PHP_VERSION=$PHP_VERSION" -e "DDEV_PROJECT_TYPE=$project_type" -d --name $CONTAINER_NAME -d $DOCKER_IMAGE)
	./test/containercheck.sh
	curl --fail localhost:$HOST_PORT/test/phptest.php
	# Make sure that the project-specific config has been linked in.
	docker exec -it $CONTAINER grep "# ddev $project_type config" /etc/nginx/nginx-site.conf
	# Make sure that the right PHP version was selected for the project_type
	# Only drupal6 is currently different here.
	docker exec -it $CONTAINER php --version | grep "PHP $PHP_VERSION"

	# Make sure we don't have lots of "closed keepalive connection" complaints
	docker logs $CONTAINER | grep -v "closed keepalive connection"
	# Make sure both nginx logs and fpm logs are being tailed
	docker logs $CONTAINER | grep "==> /var/log/nginx/error.log" >/dev/null
	docker logs $CONTAINER | grep "==> /var/log/php-fpm.log" >/dev/null

	# Make sure that backdrop drush commands were added on backdrop and only backdrop
	if [ "$project_type" == "backdrop" ] ; then
	 	# The .drush/commands/backdrop directory should only exist for backdrop apptype
		docker exec -it $CONTAINER bash -c 'if [ ! -d  /root/.drush/commands/backdrop ] ; then exit 1; fi'
	else
		docker exec -it $CONTAINER bash -c 'if [ -d  /root/.drush/commands/backdrop ] ; then exit 2; fi'
	fi
	docker rm -f $CONTAINER
done

echo "testing use of custom nginx config"
docker run -p $HOST_PORT:$CONTAINER_PORT -e "DOCROOT=potato" -v `pwd`/test/test-custom.conf:/var/www/html/.ddev/nginx-site.conf -d --name $CONTAINER_NAME -d $DOCKER_IMAGE
docker exec -it $CONTAINER_NAME cat /etc/nginx/sites-enabled/nginx-site.conf | grep "docroot is /var/www/html/potato in custom conf"

