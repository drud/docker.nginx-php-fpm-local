#!/bin/bash
while true;
do
    status="$(docker ps --format "{{.Status}}" --filter "name=$CONTAINER_NAME" | sed  's/.*(\(.*\)).*/\1/')"
    if [[ "$status" == "healthy" ]]
    then
        break
    fi
    sleep 2
done
exit 0
