#!/bin/bash

#-----------------------------------------------------------------------------
USER_IP="" # specify it
USER_NAME="" # specify it
# user path where to save resources
LOG_FILE="/etc/wireguard/logs/$USER_NAME/resources"
#-----------------------------------------------------------------------------

#=============================================================================
#=============================================================================

# get file size before writing (zero if file doesn't exist)
if test -f $LOG_FILE; then
    before_fs=$(ls -l $LOG_FILE | awk '{print $5}');
else
    before_fs=0;
fi

# exit after 25 seconds or after 20 packets
timeout 25 tcpdump -c 20 host $USER_IP | grep "IP" | awk '{print$3 ,$4 ,$5}' | sed 's/://' >> $LOG_FILE

# get file size after writting
after_fs=$(ls -l $LOG_FILE | awk '{print $5}')

if [ $after_fs -ne $before_fs ]; then
    # write only when we captured packets
    echo "---------------------------------------------------------------------------" >> $LOG_FILE;
fi

logger resources logger script is just executed
