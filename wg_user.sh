#!/bin/bash

# ----------------------------------------------------------------------------
# include file with colors
source colors
# ----------------------------------------------------------------------------
HOSTS_FILE_NAME="wg_hosts"
INTERFACE_NAME="wg0"
PUB_KEY_PATH="/etc/wireguard/keys/"
# ----------------------------------------------------------------------------
get_user_public_key()
{
    file=$(find $PUB_KEY_PATH -type f -name $1*.public)
    key=$(cat $file)
    echo $key
}
# ----------------------------------------------------------------------------
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
# ----------------------------------------------------------------------------
add_user()
{   
    ip=$(find_user_ip $1)
    # get user public key
    pub_key=$(get_user_public_key $1)
    # add user to wireguard
    wg set $INTERFACE_NAME peer $pub_key allowed-ips "$ip/32"
    echo -e "\t${GREEN}Added ${LIGHT_CYAN}$1 | $ip | $pub_key ${GREEN}to wireguard${NC}";
}
# ----------------------------------------------------------------------------
del_user()
{
    # get user public key
    pub_key=$(get_user_public_key $1)
    # delete user from wireguard
    wg set $INTERFACE_NAME peer $pub_key remove
    echo -e "\t${RED}Deleted ${LIGHT_CYAN}$1 | $pub_key ${RED}from wireguard${NC}";
}
# ----------------------------------------------------------------------------
select_action()
{
    if [ $1 = "-a" ]; then
        add_user $2;
    else
        del_user $2;
    fi
}
# ----------------------------------------------------------------------------

#=============================================================================
#=============================================================================

# check action: -a (add user) -r (remove user)
if [[ $1 != "-a" && $1 != "-r" ]]; then 
    echo -e "\t${RED}Specify action: {-a (add), -r (remove)} [user]${NC}"
    exit;
else
    # check is user name is specified
    if [ -z $2 ]; then
        echo -e "\t${RED}Specify user name${NC}";
        exit;
    fi
    # run needed fucntion
    select_action $1 $2;
fi
