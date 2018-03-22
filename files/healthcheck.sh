#!/bin/bash

# nginx and php-fpm healthcheck

set -eo pipefail

curl --fail localhost:8080/fpmstatus
curl --fail localhost:8080/healthcheck/
curl --fail localhost:8025 >/dev/null 2>&1