#!/bin/bash

# Run tests of nginx-php-fpm-local container
# NOTE: This requires the "realpath" tool, easiest installed with:
#   MacOS: brew install coreutils
#   Debian/Ubuntu: apt-get install realpath

set -o errexit
set -x

# First arg is the image (full with tag)
image=$1
# Get the directory where this script lives, so we can find container_health_check.sh as well
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

now=$(date +%s)
export CONTAINER_NAME=web-local-test

# docker will be angry with us if we use /tmp instead of /private/tmp (OSX), so expand to /private/tmp
tmpdir=$(realpath $(mktemp -d -t docrootXXXXX))
docker run -p 1081:80 -u 1000 -v $tmpdir:/var/www/html/docroot/mounted -d --name $CONTAINER_NAME -d $image
$MYDIR/container_health_check.sh

function finish {
	docker stop $CONTAINER_NAME && docker rm $CONTAINER_NAME
	rm -rf $tmpdir
}
trap finish EXIT

# Simple check to make sure PHP is working and is PHP7
docker exec -it $CONTAINER_NAME php --version | grep "PHP 7"
# Test that email can be sent
curl -s localhost:1081/test/test-email.php | grep "Test email sent"

host_fname=created_on_host.txt
touch $tmpdir/$host_fname
host_user=$(docker exec -it $CONTAINER_NAME ls -l /var/www/html/docroot/mounted/$host_fname | awk '{print $3;}')
host_group=$(docker exec -it $CONTAINER_NAME ls -l /var/www/html/docroot/mounted/$host_fname | awk '{print $4;}')
if [ $host_user != 'nginx' -o $host_group != 'nginx' ] ; then
	echo "Incorrect container-side host or group, user=$host_user group=$host_group"
	exit 4
fi

# Create a file in the shared volume; it will have the nginx user/group within container
container_fname=created_in_container_$now.txt
# Odd bash -c is forced by docker exec bug returning 129 even from successful commands
docker exec -it $CONTAINER_NAME bash -c "touch /var/www/html/docroot/mounted/$container_fname; exit \$?"

# It should be owned by current user in $tmpdir on the host
local_user=$(ls -l $tmpdir/$container_fname | awk '{print $3;}')
local_group=$(ls -l $tmpdir/$container_fname | awk '{print $4;}')
if [ "$local_user" != "$USER" ] ; then
  echo "Incorrect local_user=$local_user on file $tmpdir/$container_fname: $(ls -l $tmpdir/$container_fname)"
  exit 1
fi
echo "Local file has correct local_user=$local_user"
if [ "$local_group" != "$(id -g -n $USER)" ]; then
  echo "Incorrect local_group=$local_group on file $tmpdir/$container_fname: $(ls -l $tmpdir/$container_fname)"
  exit 2
fi
echo "Local file has correct local_group=$local_group"
