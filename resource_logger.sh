#!/bin/bash

# ----------------------------------------------------------------------------
WORK_PATH="/etc/wireguard"
# ----------------------------------------------------------------------------
# include file with colors
source $WORK_PATH/colors
#-----------------------------------------------------------------------------
HOSTS_FILE_NAME="$WORK_PATH/wg_hosts"
#-----------------------------------------------------------------------------
find_user_ip()
{  
    # read all hosts
    while read line; do 
        read name ip <<< $line;
        # get ip of the user
        if [ $1 = $name ]; then
            echo $ip;
        fi
    done < $HOSTS_FILE_NAME
}
#-----------------------------------------------------------------------------

#=============================================================================
#=============================================================================

# check if user is specified
if [ -z $1 ]; then
    echo -e "\t{RED}Specify user name${NC}";
    exit;
fi
#-----------------------------------------------------------------------------
USER_NAME=$1
# user path where to save resources
LOG_FILE="/etc/wireguard/logs/$USER_NAME/resources"
#-----------------------------------------------------------------------------
# get user ip address
USER_IP=$(find_user_ip $USER_NAME)
#-----------------------------------------------------------------------------
# get file size before writing (zero if file doesn't exist)
if test -f $LOG_FILE; then
    before_fs=$(ls -l $LOG_FILE | awk '{print $5}');
else
    before_fs=0;
fi
#-----------------------------------------------------------------------------
# exit after 25 seconds or after 20 packets
timeout 25 tcpdump -c 20 host $USER_IP | grep "IP" | awk '{print$3 ,$4 ,$5}' | sed 's/://' >> $LOG_FILE
#-----------------------------------------------------------------------------
# get file size after writting
after_fs=$(ls -l $LOG_FILE | awk '{print $5}')
#-----------------------------------------------------------------------------
# if file size is changed, then write separator
if [ $after_fs -ne $before_fs ]; then
    # write only when we captured packets
    echo "---------------------------------------------------------------------------" >> $LOG_FILE;
fi
#-----------------------------------------------------------------------------
# log it to syslog
logger resources logger script with user [$USER_NAME] is just executed
