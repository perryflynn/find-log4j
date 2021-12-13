# by Christian Blechert <christian@serverless.industries>

# ATTENTION! It only checks ext3 + ext4 filesystems right now!
# Extend it if you use something else

while read -u 3 -r JAR
do

    JAR=$(echo "$JAR" | sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//')

    if [ -z "$JAR" ]; then
        continue
    fi

    NUM=$(unzip -l "$JAR" | grep -P "^\s+[0-9]+\s+[0-9-]+\s+[0-9:]+\s+.+" | awk '{print $4}' | grep -P 'org/apache/(log4j|logging/log4j)' | wc -l)

    if [ $NUM -gt 0 ]; then
        echo "$JAR"
    fi

done 3<<< "$(find / \( -fstype ext4 -or -fstype ext3 -or -fstype zfs \) -type f -name "*.jar" 2> /dev/null)"

# eof