#!/bin/bash

# Finds log4j resources in running docker containers
# by Christian Blechert <christian@serverless.industries>

while read -r CONTAINER
do

    CONTAINER=$(echo "$CONTAINER" | sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//')

    if [ -z "$CONTAINER" ]; then
        continue
    fi

    while read -u 3 -r JAR
    do

        JAR=$(echo "$JAR" | sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//')

        if [ -z "$JAR" ]; then
            continue
        fi

        rm -f moep.jar
        docker cp "$CONTAINER:$JAR" moep.jar
        NUM=$(unzip -l moep.jar | grep -P "^\s+[0-9]+\s+[0-9-]+\s+[0-9:]+\s+.+" | awk '{print $4}' | grep -P 'org/apache/(log4j|logging/log4j)' | wc -l)

        if [ $NUM -gt 0 ]; then
            echo "$CONTAINER @ $JAR"
        fi

    done 3<<< "$(docker exec -u root $CONTAINER find / -type f -name "*.jar" 2> /dev/null)"

done <<< "$(docker ps --format '{{.Names}}')"

# eof