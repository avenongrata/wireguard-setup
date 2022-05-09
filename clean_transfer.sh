#!/bin/bash

LOG_PATH=/etc/wireguard/logs/

for dir in `find $LOG_PATH -type d`
do
   # pass current dir
   if [[ $dir == $LOG_PATH ]];
   then 
    continue
   fi
   > $dir/transferRx;
   > $dir/transferTx;
done
