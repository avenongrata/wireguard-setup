#!/bin/bash

# ----------------------------------------------------------------------------
# include file with colors
source colors
# ----------------------------------------------------------------------------
# current working path
CUR_PATH="./"

# wireguard server config name
WG_SERVER_CONFIG_FILE=$CUR_PATH"wg0.conf"
# wireguard server public key
SERVER_PUBLIC_KEY="" # specify it
# wireguard server ip:port
SERVER_ENDPOINT="" # specify it
# file where next possible ip addr for new client is stored
IP_FILE_NAME=$CUR_PATH"next_ip"

# file where stores user-name ip-addr
HOSTS_FILE_NAME=$CUR_PATH"wg_hosts"
# directory name where configs are stored
CONFIG_DIR=$CUR_PATH"configs/"
# directory name where keys are stored
KEYS_DIR=$CUR_PATH"keys/"

# the final part of user wireguard config file name
USER_CONFIG_NAME="_wg.conf" # specify it
# the final part of user wireguard private key file name
USER_PRIVATE_KEY_FILE_NAME=".private"
# the final part of user wireguard public key file name
USER_PUBLIC_KEY_FILE_NAME=".public"
# ----------------------------------------------------------------------------
# check if file name is specified
check_name()
{
    if [ -z $1 ]; then 
        echo -e "\t${RED}Specify name for config${NC}"; 
        exit 1;
    else
        echo -e "\t${GREEN}Got config name${LIGHT_CYAN}\t\t" $1 "${NC}";
    fi
}
# ----------------------------------------------------------------------------
# get last octet from ip addr
get_last_octet()
{
    IFS=. read ip1 ip2 ip3 ip4 <<< "$1"
    echo $ip4
}
# ----------------------------------------------------------------------------
# create new ip address
create_new_ip()
{
    IFS=. read ip1 ip2 ip3 ip4 <<< "$1"
    echo $ip1.$ip2.$ip3.$2
}
# ----------------------------------------------------------------------------
# add user to wireguard server config file
add_user()
{
    # add user name to config to simplify identification
    echo -e "\n# $3" >> $WG_SERVER_CONFIG_FILE
    echo -e "[Peer]" >> $WG_SERVER_CONFIG_FILE
    echo -e "PublicKey =" $1 >> $WG_SERVER_CONFIG_FILE
    echo -e "AllowedIPs =" $2"/32" >> $WG_SERVER_CONFIG_FILE
}
# ----------------------------------------------------------------------------
# create user wireguard config file
create_user_config()
{   
    # create file
    touch $1
    echo -e "[Interface]" >> $1
    echo -e "PrivateKey =" $2 >> $1
    echo -e "Address =" $3"/32" >> $1
    echo -e "DNS = 8.8.8.8" >> $1
    
    echo -e "\n[Peer]" >> $1
    echo -e "PublicKey =" $SERVER_PUBLIC_KEY >> $1
    echo -e "Endpoint =" $SERVER_ENDPOINT >> $1
    echo -e "AllowedIPs = 0.0.0.0/0" >> $1
    echo -e "PersistentKeepalive = 20" >> $1    
}
# ----------------------------------------------------------------------------
# check if user config file exist
check_user_config_file()
{
    if test -f "$1"; then 
        echo -e "\t${RED}User config file already exist${NC}"; 
        exit 1;
    fi
}
# ----------------------------------------------------------------------------
# check if directory exist and create if not
check_dir()
{
    if ! test -d $1; then
        mkdir $1;
        echo -e "\t${GREEN}Created directory \t${LIGHT_CYAN}$1${NC}";
    fi
}
# ----------------------------------------------------------------------------

# ============================================================================
# ============================================================================

# check if needed directories are exist and create if not
check_dir $CONFIG_DIR
check_dir $KEYS_DIR
# ----------------------------------------------------------------------------
# check for config name
check_name $1
USER_NAME=$1
# ----------------------------------------------------------------------------
# create wireguard config file name 
USER_FULL_CONFIG_NAME=$CONFIG_DIR$USER_NAME${USER_CONFIG_NAME}
# ----------------------------------------------------------------------------
# check if user config file exist in current directory
check_user_config_file $USER_FULL_CONFIG_NAME
# ----------------------------------------------------------------------------
# get next free ip-addr from file
USER_IP_ADDR=$(cat ${IP_FILE_NAME})
echo -e "\t${GREEN}Ip addr for config is${LIGHT_CYAN}\t" $USER_IP_ADDR ${NC}
# ----------------------------------------------------------------------------
# create and write new free ip addr to file
LAST_OCTET=$(get_last_octet $USER_IP_ADDR)
NEXT_IP_OCTET=$(($LAST_OCTET+1))
NEW_IP_ADDR=$(create_new_ip $USER_IP_ADDR $NEXT_IP_OCTET)
# write to file new free ip addr
echo $NEW_IP_ADDR > $IP_FILE_NAME
echo -e "\t${GREEN}Wrote to file new ip ${LIGHT_CYAN}\t" $NEW_IP_ADDR "${NC}"
# ----------------------------------------------------------------------------
# generate new wireguard keys for user and save to files
wg genkey | tee $KEYS_DIR$USER_NAME$USER_PRIVATE_KEY_FILE_NAME | wg pubkey > $KEYS_DIR$USER_NAME$USER_PUBLIC_KEY_FILE_NAME
USER_PRIVATE_KEY=$(cat $KEYS_DIR$USER_NAME$USER_PRIVATE_KEY_FILE_NAME)
USER_PUBLIC_KEY=$(cat $KEYS_DIR$USER_NAME$USER_PUBLIC_KEY_FILE_NAME)
echo -e "\t${GREEN}Generated public and private user keys${NC}"
# ----------------------------------------------------------------------------
# add new user to wireguard server
add_user $USER_PUBLIC_KEY $USER_IP_ADDR $USER_NAME
echo -e "\t${GREEN}Added user info to wireguard server${NC}"
# ----------------------------------------------------------------------------
# check flag -r from command line and restart wireguard server if specified
if [[ -n $2 && $2 = "-r" ]]; then 
    echo -e "\t${GREEN}Restarted wireguard server${NC}";
    systemctl restart wg-quick@wg0;
else
    echo -e "\t${RED}Wireguard server will not be restarted${NC}";
fi
# ----------------------------------------------------------------------------
# create wireguard config file
create_user_config $USER_FULL_CONFIG_NAME $USER_PRIVATE_KEY $USER_IP_ADDR
echo -e "\t${GREEN}Created user config file${LIGHT_CYAN}" $USER_FULL_CONFIG_NAME ${NC}
# ----------------------------------------------------------------------------
# add user name and ip to hosts file
echo $USER_NAME $USER_IP_ADDR >> $HOSTS_FILE_NAME
echo -e "\t${GREEN}Added user ${LIGHT_CYAN} $USER_NAME ${GREEN} with ip ${LIGHT_CYAN} $USER_IP_ADDR ${GREEN} to $HOSTS_FILE_NAME ${NC}"
# ----------------------------------------------------------------------------
