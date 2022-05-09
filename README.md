# wireguard-setup
Allows you setup wireguard server.

  - clean_transfer.sh - for cleaning transfer logs
  - colors - for pretty printing
  - create_crontab_job - for adding job to crontab (every 10 minutes)
  - gen_config.sh - generate config for new user
  - log.py - scripts for logging (ip, rx/tx-bytes count)
  - log.sh - script for running logging (log.py)
  - next_ip - contains next free ip address for user
  - ping.sh - ping all users and show online|offline
  - resource_logger.sh - catch 20 packets from user (gets only ip)
  - wg_hosts - who is using wireguard server
  - wg_startup_howto.txt - how to setup wireguard server
  - wg_user.sh - add/delete user from wireguard server without restarting it
