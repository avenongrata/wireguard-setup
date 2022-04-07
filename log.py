import json
import os
from datetime import datetime
import syslog

# working path
work_path = "/etc/wireguard/"
# use it for test
#work_path = "./"

# time when script is running
script_time = datetime.today()

# file name with all hosts
wg_hosts = work_path + "wg_hosts"

# wg-json script path
wg_json_path = "/usr/share/doc/wireguard-tools/examples/json/wg-json"
# use it for test
#wg_json_path = "cat wg.txt"

# open a pipe to command line
stream = os.popen(wg_json_path)
# get wg information about users
output = "".join(stream.readlines())
# work with json file
wg_data = json.loads(output)


def get_json_value(base, key):
    """
    Try to get json value from key
    :param base: where to find
    :param key: key to find
    :return: None when didn't find, value otherwise
    """
    try:
        val = base[key]
    except KeyError:
        return None

    return val


def get_endpoint(peer):
    """
    Gets ip and port from user
    :param peer: where to find
    :return: Ip and port if found, None otherwise
    """
    endpoint = get_json_value(peer, "endpoint")
    if endpoint:
        ip, port = endpoint.split(":")
    else:
        return None

    return {ip: port}


def get_last_handshake(peer):
    """
    Count how long has it been since the last handshake
    :param peer: peer information
    :return: how many yyyy:mm:dd hh:mm:ss past after last handshake
    """
    handshake = get_json_value(peer, "latestHandshake")
    if not handshake:
        return None

    date = datetime.fromtimestamp(handshake)
    duration = datetime.today() - date
    return duration


def get_transfer_kb(peer, val):
    """
    Return how many kilobytes were spent by user
    :param peer: where to find
    :param val: parameter to find
    :return: Spent kilobytes if found, None otherwise
    """
    # get spent bytes from peer
    transfer_b = get_json_value(peer, val)
    if not transfer_b:
        return None

    # return kilobytes
    return transfer_b / 1000


def get_rx_kb(peer):
    """
    Return how many kilobytes were received
    :param peer: where to find
    :return: How many kilobytes when found, None otherwise
    """
    return get_transfer_kb(peer, "transferRx")


def get_tx_kb(peer):
    """
    Return how many kilobytes were sent
    :param peer: where to find
    :return: How many kilobytes when found, None otherwise
    """
    return get_transfer_kb(peer, "transferTx")


def get_allowed_ips(peer):
    """
    Get interface's ips for user
    :param peer: where to find
    :return:
    """
    ips = get_json_value(peer, "allowedIps")
    if not ips:
        return None

    user_ips = []
    for ip in ips:
        ip = ip.split("/")[0]
        user_ips.append(ip)

    return user_ips


def get_hosts(file):
    """
    Gets all hosts from special file
    :param file: file name where hosts are stored
    :return: None if error occurred, hosts otherwise
    """
    try:
        host_fd = open(file, "r")
    except FileNotFoundError:
        syslog.syslog(syslog.LOG_ERR, "Can't find file with hosts: {}".format(file))
        return None

    hosts = host_fd.readlines()
    host_fd.close()
    if not hosts:
        return None

    return hosts


def get_username(hosts, ip):
    """
    Find username for ip address
    :param hosts: list of hosts
    :param ip: which ip to find
    :return: Username if found, None otherwise
    """
    for host in hosts:
        if host.find(ip) == -1:
            continue

        return host.split(" ")[0]

    return None


def create_dir(dir_name) -> None:
    """
    Create directory if it doesn't exist yet
    :param dir_name: directory name (with path)
    :return: None (I hope, that it's always possible to create directory)
    """
    # when directory already exist
    if os.path.isdir(dir_name):
        return

    os.mkdir(dir_name)
    # write to syslog
    syslog.syslog(syslog.LOG_INFO, "Created directory: {}".format(dir_name))


def create_log_dir(path):
    """
    Create log-directory if it doesn't exist yet
    :param path: path where to create
    :return: Directory name with work path
    """
    dir_name = path + "logs/"
    create_dir(dir_name)
    return dir_name


def create_user_log_dir(path, username):
    """
    Create user-log-directory if it doesn't exist yet
    :param path: path where to create
    :param username: username (name for directory)
    :return: Directory name with work path
    """
    dir_name = path + username + "/"
    create_dir(dir_name)
    return dir_name


def create_file(file_name) -> None:
    """
    Create a file if it doesn't exist yet
    :param file_name: file name which to create
    :return: None
    """
    # file already exist
    if os.path.isfile(file_name):
        return
    # create file
    os.mknod(file_name)
    syslog.syslog(syslog.LOG_INFO, "Created new file: {}".format(file_name))


def add_endpoint(fd, endpoint) -> None:
    """
    Add endpoint to the file
    :param fd: file descriptor
    :param endpoint: endpoint from user
    :return: None
    """
    data = "{}{:>20}\n".format(script_time.__str__(), endpoint)
    fd.write(data)


def get_values(l) -> list:
    """
    Gets list with spaces and return new list only with values
    :param l: uncleared list
    :return: cleared list (only values, without spaces)
    """
    new_l = []
    for x in l.split():
        if not len(x):
            continue
        else:
            new_l.append(x)

    return new_l


def handle_endpoint(file, endpoint) -> None:
    """
    Append endpoint to the file. Don't do smth when endpoint is already in file
    :param file: log file name
    :param endpoint: endpoint from user
    :return:
    """
    # this check is unnecessary, but let it be
    try:
        fd = open(file, "r+")
    except FileNotFoundError:
        syslog.syslog(syslog.LOG_ERR, "Can't find file with endpoints: {}".format(file))
        return None

    # read all possible endpoints
    endpoints = fd.readlines()
    # when file is empty, then just add to the file
    if not endpoints:
        add_endpoint(fd, endpoint)
        fd.close()
        return

    ips = set()
    # get all ip
    for point in endpoints:
        # get all values without spaces
        point = get_values(point)
        # get only ip, without time
        point = point[2].rstrip()
        ips.add(point)

    # add point if there isn't such
    if endpoint not in ips:
        add_endpoint(fd, endpoint)
        fd.close()


def handle_endpoints(path, endpoint):
    """
    Create file (when it isn't exist) for logging endpoints and append unique endpoint (when doesn't exist such)
    :param path:
    :param endpoint:
    :return:
    """
    f_path = path + "endpoints"
    # create file when doesn't exist
    create_file(f_path)
    # add an endpoint if there isn't one yet
    handle_endpoint(f_path, endpoint)


def add_transfer_data(fd, cur_kb, more) -> None:
    """
    Write to the log file transfer data
    :param fd: file descriptor
    :param cur_kb: how many kilobytes are spent now
    :param more: how many kilobytes more than it was
    :return: None
    """
    data = data = "{}{:>19}{:>28}\n".format(script_time.__str__(), str(cur_kb), str(more))
    fd.write(data)


def add_transfer(fd, last_kb, cur_kb) -> None:
    """
    Write to file how many kilobytes were spent and nothing when it's equal to zero
    :param fd: file descriptor
    :param last_kb: how many kilobytes were spent at the last time checking
    :param cur_kb: how many kilobytes are spent at current time
    :return: None
    """
    # how many kilobytes more than it was
    more = cur_kb - last_kb
    # when nothing was spent or empty file
    if not more:
        return

    # write to file
    add_transfer_data(fd, cur_kb, more)


def handle_transfer(file, kb) -> None:
    """
    Create log file when it doesn't exist and write transfer data to it
    :param file: log file name
    :param kb: how many kilobytes were spent at current time
    :return: None
    """
    # this check is unnecessary, but let it be
    try:
        fd = open(file, "r+")
    except FileNotFoundError:
        syslog.syslog(syslog.LOG_ERR, "Can't find file with transfers: {}".format(file))
        return None

    # read all information about transfer data
    transfers = fd.readlines()
    # convert from str to int
    kb = float(kb)
    # when file is empty, then just add to the file
    if not transfers:
        add_transfer(fd, 0, kb)
        fd.close()
        return

    # get values without spaces
    transfer = get_values(transfers[-1])
    # write to file current spent data and difference between current and last time (if not 0)
    add_transfer(fd, float(transfer[2]), kb)
    fd.close()


def handle_transfer_rx(path, rx_kb) -> None:
    """
    Write to log file spent kilobytes if necessary
    :param path: file name
    :param rx_kb: how many kilobytes were received
    :return: None
    """
    f_path = path + "transferRx"
    # create file when doesn't exist
    create_file(f_path)
    # write to file current spent kilobytes and the difference between the last time. Nothing when equal to zero
    handle_transfer(f_path, rx_kb)


def handle_transfer_tx(path, tx_kb) -> None:
    """
    Write to log file spent kilobytes if necessary
    :param path: file name
    :param tx_kb: how many kilobytes were transferred
    :return: None
    """
    f_path = path + "transferTx"
    # create file when doesn't exist
    create_file(f_path)
    # write to file current spent kilobytes and the difference between the last time. Nothing when equal to zero
    handle_transfer(f_path, tx_kb)


# to simplify (can be changed)
peers = wg_data["wg0"]["peers"]
# get all hosts from file
hosts = get_hosts(wg_hosts)
if not hosts:
    exit(1)
# create directory for add log-files and directories (when it doesn't exist)
log_dir_path = create_log_dir(work_path)
# log all peers
for peer in peers:
    # peer information
    peer_data = peers[peer]
    # get endpoint from peer
    end_point = get_endpoint(peer_data)
    # get last handshake between server and user
    #print(get_last_handshake(peer_data))
    # get transferRx kilobytes
    rx_kb = get_rx_kb(peer_data)
    # get transferTx kilobytes
    tx_kb = get_tx_kb(peer_data)
    # get allowed ips for user
    allowed_ips = get_allowed_ips(peer_data)
    # get path to user logging directory
    user_log_dir = create_user_log_dir(log_dir_path, get_username(hosts, allowed_ips[0]))
    # when user endpoint exist (has been connected at least once)
    if end_point:
        # get only ip address from endpoint information
        handle_endpoints(user_log_dir, list(end_point.keys())[0])
    # when user has been transferred something
    if rx_kb or tx_kb:
        # log information about received count
        handle_transfer_rx(user_log_dir, rx_kb)
        # log information about transferred count
        handle_transfer_tx(user_log_dir, tx_kb)
