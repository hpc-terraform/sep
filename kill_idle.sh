
#!/bin/bash

threshold=0.1
count=0
wait_minutes=40

while true
do

load=$(uptime | sed -e 's/.*load average: //g' | awk '{ print $1 }') # 1-minute average load
load="${load//,}" # remove trailing comma
ssh_flag=$(ss | grep -i ssh | wc -l)
load_flag=$(echo $load'<'$threshold | bc -l)

if (( $load_flag ))
then
    echo "Idling CPU"
    if ! (( $ssh_flag ))
    then
        echo "Idling SSH"
        ((count+=1))
    else
        count=0
    fi
else
    count=0
fi
echo "Idle minutes count = $count"

if (( count>wait_minutes ))
then
    echo Shutting down
    sleep 300
    sudo poweroff
fi

sleep 60
done
