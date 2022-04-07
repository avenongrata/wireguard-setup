#!/bin/sh

# check if script if specified
if [ -z $1 ]; then
	echo "Script isn't specified";
	return;
fi

sudo crontab -l > cron_bkp
# add job for every 10 minutes
sudo echo "*/10 * * * * sudo $1 >/dev/null 2>&1" >> cron_bkp
sudo crontab cron_bkp
sudo rm cron_bkp
