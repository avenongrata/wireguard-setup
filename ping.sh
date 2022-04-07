#!/bin/bash

# ----------------------------------------------------------------------------
# include file with colors
source colors
# ----------------------------------------------------------------------------
HOSTS_FILE_NAME="wg_hosts"
# ----------------------------------------------------------------------------
ping_addr()
{
    # ping addr
    if ping -c 1 $2 &> /dev/null; then 
        echo -e "\t${LIGHT_CYAN}$2 ${GREEN}\tonline\t\t${YELLOW}$1${NC}";
    else
        echo -e "\t${LIGHT_CYAN}$2 ${RED}\toffline\t\t${YELLOW}$1${NC}"
fi
}
# ----------------------------------------------------------------------------
ping_all_hosts()
{
    while read line; do 
        read name ip <<< $line;
        ping_addr $name $ip;
    done < $HOSTS_FILE_NAME
}
# ----------------------------------------------------------------------------

# ============================================================================
# ============================================================================

# check all hosts
ping_all_hosts