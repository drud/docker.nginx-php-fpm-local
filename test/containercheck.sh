#!/bin/bash

for i in `seq 1 60`;
do
    # status contains uptime and health in parenthesis, sed to return health
    status=$(docker ps --format "{{.Status}}" --filter "name=$CONTAINER_NAME" | sed  's/.*(\(.*\)).*/\1/')
    if [ "$status" = "healthy" ]; then
        exit 0
    fi
    sleep 1
done
exit 1
