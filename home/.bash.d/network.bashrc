#
# Network
#

# list active ports
alias net_active_ports='netstat -tulanp'
# list listening apps
alias net_listen_proc='lsof -P -i -n'
# show public ip
alias ip_public='curl -s ifconfig.me'
# Do not wait interval 1 second, go fast
alias ping_fast='ping -c 100 -s.2'
# display all iptables rules
alias iptables_list='sudo iptables -L -n -v --line-numbers'
alias iptables_list_in='sudo iptables -L INPUT -n -v --line-numbers'
alias iptables_list_out='sudo iptables -L OUTPUT -n -v --line-numbers'
alias iptables_list_fw='sudo iptables -L FORWARD -n -v --line-numbers'

# https://nbviewer.org/github/rasbt/python_reference/blob/master/tutorials/useful_regex.ipynb  + copilot to adapt it to bash regex

function is_ipv4()
{
  local regex='^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
  [[ $1 =~ $regex ]]
}

function is_ipv6()
{
  local regex='^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*$'
  [[ $1 =~ $regex ]]
}

function is_ip()
{
  is_ipv4 "$1" || is_ipv6 "$1"
}

function is_mac_addr()
{
  local regex='^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$'
  [[ $1 =~ $regex ]]
}

function is_url()
{
  local regex='^[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,}$'
  [[ $1 =~ $regex ]]
}

function is_http()
{
  local regex='^(https?|http?)://[-[:alnum:]\+&@#/%?=~_|!:,.;]*[-[:alnum:]\+&@#/%=~_|]$'
  [[ $1 =~ $regex ]]
}

function is_uri()
{
  local regex='^(https?|sftp)://[-[:alnum:]\+&@#/%?=~_|!:,.;]*[-[:alnum:]\+&@#/%=~_|]$'
  [[ $1 =~ $regex ]]
}

function is_email_addr()
{
  local regex="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"
  [[ $1 =~ $regex ]]
}

#
# Nmap
#

alias nmap_scan_fast='nmap -F'
alias nmap_scan_vuln='nmap -Pn --script vuln'
alias nmap_scan_malware='nmap -p80 --script http-google-malware'

function nmap_find_printers()
{
  local __host=${1:-192.168.1.1}

  nmap -p 9100,515,631 $__host/24
}

#
# Bash
#

function udp_send() {
  _arg_assert_exists "$1" "usage: udp_send <host> <port> msg..." || return
  _arg_assert_exists "$2" "usage: udp_send <host> <port> msg..." || return
  _arg_assert_exists "$3" "usage: udp_send <host> <port> msg..." || return

  local __host=$1
  local __port=$2
  shift
  shift

  echo "$@" >/dev/udp/$__host/$__port
}

function tcp_send() {
  _arg_assert_exists "$1" "usage: tcp_send <host> <port> msg..." || return
  _arg_assert_exists "$2" "usage: tcp_send <host> <port> msg..." || return
  _arg_assert_exists "$3" "usage: tcp_send <host> <port> msg..." || return

  local __host=$1
  local __port=$2
  shift
  shift

  echo "$@" >/dev/tcp/$__host/$__port
}

function tcp_client()
(
  _arg_assert_exists "$1" "usage: tcp_client <host> <port>" || return
  _arg_assert_number "$2" "usage: tcp_client <host> <port>" || return

  local __host=$1
  local __port=$2
  local __input
  local __dummy

  function connection_closed_by_peer() {
    echo "Connection closed by peer"
    exit 1
  }

  function close_co() { exec 3>&-; exec 3<&-; exit; }

  function read_srv() {
    if read -t $1 -u 3 __dummy; then
      cat <&3 || exit
    fi
  }

  function process_input() {
    case "$1" in
      "")
        read_srv 0.2
        ;;
      /help)
        echo "Type /exit to exit"
        ;;
      /exit)
        close_co
        ;;
      *)
        echo $1 >&3
        read_srv 0.2
        ;;
    esac
  }

  # better quit if connection is closed by peer
  trap connection_closed_by_peer PIPE
  # quit if SIGINT received
  trap close_co INT

  # connect to host:port
  exec 3<>/dev/tcp/$__host/$__port || return

  process_input "/help"

  # initial read
  read_srv 0.2

  while true; do
    if bin_exists gum; then
      __input=$(gum input)
      echo "> $__input"
    else
      echo -n "> "
      read __input
    fi

    process_input "$__input"
  done
)

function tcp_scan() {
  _arg_assert_exists "$1" "usage: tcp_scan <host> [port-min] [port-max]" || return

  local __host=$1
  local __port_min=${2:-1}
  local __port_max=${3:-65535}

  seq $__port_min $__port_max | while read port; do \
    echo $port 2>/dev/null >/dev/tcp/$__host/$port && echo $port open; \
  done

  true
}

#
# Netcat
#

function udp_send_nc() {
  _arg_assert_exists "$1" "usage: udp_send <host> <port> msg..." || return
  _arg_assert_exists "$2" "usage: udp_send <host> <port> msg..." || return
  _arg_assert_exists "$3" "usage: udp_send <host> <port> msg..." || return

  local __host=$1
  local __port=$2
  shift
  shift

  echo "$@" | netcat -Nu -w0 $__host $__port
}

function tcp_send_nc() {
  _arg_assert_exists "$1" "usage: tcp_send <host> <port> msg..." || return
  _arg_assert_exists "$2" "usage: tcp_send <host> <port> msg..." || return
  _arg_assert_exists "$3" "usage: tcp_send <host> <port> msg..." || return

  local __host=$1
  local __port=$2
  shift
  shift

  echo "$@" | netcat -N -w0 $__host $__port
}

function socket_send() {
  _arg_assert_exists "$1" "usage: socket_send <path_to_unix_socket> msg..." || return
  _arg_assert_exists "$2" "usage: socket_send <path_to_unix_socket> msg..." || return

  local __path=$1
  shift

  echo "$@" | netcat -N -U $__path
}

function udp_srv() {
  _arg_assert_exists "$1" "usage: udp_srv <port>" || return

  local __port=$1

  netcat -luk -p $__port
}

function tcp_srv() {
  _arg_assert_exists "$1" "usage: tcp_srv <port>" || return

  local __port=$1

  netcat -lk -p $__port
}

function socket_srv() {
  _arg_assert_exists "$1" "usage: socket_srv <path_to_unix_socket>" || return

  local __path=$1

  netcat -lUk $__path
}

function udp_listen() {
  _arg_assert_exists "$1" "usage: udp_listen <port>" || return

  local __port=$1

  netcat -lu -W1 -p $__port
}

function tcp_listen() {
  _arg_assert_exists "$1" "usage: tcp_listen <port>" || return

  local __port=$1

  netcat -l -p $__port
}

function socket_listen() {
  _arg_assert_exists "$1" "usage: socket_listen <path_to_unix_socket>" || return

  local __path=$1

  netcat -lU $__path
}

#
# Web
#

# get web server headers
alias http_headers='curl -LI -A Mozilla/5.0'
# find out if remote server supports gzip / mod_deflate or not
alias http_headers_compression='curl -LI --compressed -A Mozilla/5.0'

function http_get() (
  _arg_assert_exists "$1" "usage: http_test <host>" || return

  local __host=$1
  local __port=${2:-80}

  exec 3<>/dev/tcp/$__host/$__port || return

  echo -e "GET / HTTP/1.1\r\nhost: $__host\r\nConnection: close\r\n\r\n" >&3

  if read -t 3 -u 3 dummy; then
    cat <&3
  else
    false
  fi
)

#
# Websites utilities
#

function paste_rs() {
  # cat file | paste_rs
  # paste_rs file

  local __file=${1:-/dev/stdin}
  local __url=$(curl --data-binary @${__file} https://paste.rs)

 if ! is_shell_stdin_piped && bin_exists qrcode-terminal; then
    echo "$__url :"
    qrcode-terminal $__url
  else
    echo $__url
  fi
}

ip_infos()
{
  _arg_assert_binary curl "No curl found" || return

  local __resp=$(curl -s ipinfo.io)

  # local ip=$(echo $__resp | jq -r '.ip')
  # local hostname=$(echo $__resp | jq -r '.hostname')
  # local city=$(echo $__resp | jq -r '.city')
  # local region=$(echo $__resp | jq -r '.region')
  # local country=$(echo $__resp | jq -r '.country')
  # local coord=$(echo $__resp | jq -r '.loc')
  # local postal=$(echo $__resp | jq -r '.postal')
  # local timezone=$(echo $__resp | jq -r '.timezone')

  bin_exists jq && (echo $__resp | jq .) || echo $__resp
}

translate_from_to()
{
  _arg_assert_binary wget "No wget found" || return
  _arg_assert_exists "$1" "usage: translate_from_to {auto|fr|en|...} {fr|en|...} phrase..." || return

  local __lang_from=$1
  local __lang_to=$2
  shift
  shift
  local __query=$(echo "$@" | sed "s/[\"'<>]//g")
  local __resp=$(wget -U "Mozilla/5.0" -qO - \
    "http://translate.googleapis.com/translate_a/single?client=gtx&sl=${__lang_from}&tl=${__lang_to}&dt=t&q=${__query}")
  echo $__resp | sed "s/,,,0]],,.*//g" | awk -F'"' '{print $2, $6}'
}

translate()
{
  local __lang_to=$1
  shift
  translate_from_to auto $__lang_to "$@"
}

weather()
{
  _arg_assert_binary curl "No curl found" || return
  _arg_assert_exists "$1" "usage: weather <country>" || return

  curl -s wttr.in/$1
}

weather_diff()
{
  _arg_assert_binary curl "No curl found" || return
  _arg_assert_exists "$1" "usage: weather <country-from> <country-to>" || return
  _arg_assert_exists "$2" "usage: weather <country-from> <country-to>" || return

  diff -Naur <(curl -s http://wttr.in/$1) <(curl -s http://wttr.in/$2)
}

qr_code()
{
  _arg_assert_binary curl "No curl found" || return
  _arg_assert_exists "$1" "usage: qr_code <content>" || return

  echo $@ | curl -F-=\<- qrenco.de
}

udp_multi_srv()
{
  _arg_assert_exists "$1" "usage: udp_multi_srv <port>" || return

  local proto_type="${2:-AF_INET}"
  local srv_path
  srv_path="$(mktemp)"

  cat << EOF > "${srv_path}"
import socket
import sys

def start_server(port):
    with socket.socket(socket.${proto_type}, socket.SOCK_DGRAM) as server_socket:
        server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server_socket.bind(('0.0.0.0', port))
        print(f'Server listening on port {port}')

        while True:
            data, client_address = server_socket.recvfrom(4096)
            print(f'Client {client_address}: {data.decode()}')

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python udp_server.py <port>")
        sys.exit(1)

    port = int(sys.argv[1])
    start_server(port)
EOF

  python3 "${srv_path}" "$1"
  rm -f "${srv_path}"
}

tcp_multi_srv()
{
  _arg_assert_exists "$1" "usage: tcp_multi_srv <port>" || return

  local proto_type="${2:-AF_INET}"
  local srv_path
  srv_path="$(mktemp)"

  cat << EOF > "${srv_path}"
import socket
import sys
import threading

client_threads = {}
clients_to_remove = []

def handle_client(client_socket, client_address):
    with client_socket:
        print(f'Connected by {client_address}')
        while True:
            data = client_socket.recv(4096)
            if not data:
                print(f'Client {client_address} disconnected')
                clients_to_remove.append(client_socket)
                break
            print(f'Received message: {data.decode()}')

def start_server(port):
    with socket.socket(socket.${proto_type}, socket.SOCK_STREAM) as server_socket:
        server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server_socket.bind(('0.0.0.0', port))
        server_socket.listen(20)
        print(f'Server listening on port {port}')

        while True:
            client_socket, client_address = server_socket.accept()
            client_thread = threading.Thread(target=handle_client, args=(client_socket, client_address))
            client_threads[client_socket] = client_thread
            client_thread.start()
            for to_remove_socket in clients_to_remove:
                client_threads[to_remove_socket].join()

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python tcp_server.py <port>")
        sys.exit(1)

    port = int(sys.argv[1])
    start_server(port)
EOF

  python3 "${srv_path}" "$1"
  rm -f "${srv_path}"
}

tls_multi_srv()
{
  _arg_assert_exists "$1" "usage: tls_multi_srv <port> <certfile> <keyfile>" || return
  _arg_assert_exists "$2" "usage: tls_multi_srv <port> <certfile> <keyfile>" || return
  _arg_assert_exists "$3" "usage: tls_multi_srv <port> <certfile> <keyfile>" || return

  local port="${1}"
  local cert_file="${2}"
  local key_file="${3}"
  local proto_type="${4:-AF_INET}"
  local srv_path
  srv_path="$(mktemp)"

  cat << EOF > "${srv_path}"
import socket
import sys
import threading
import ssl

client_threads = {}
clients_to_remove = []

def handle_client(client_socket, client_address):
    with client_socket:
        print(f'Connected by {client_address}')
        while True:
            data = client_socket.recv(4096)
            if not data:
                print(f'Client {client_address} disconnected')
                clients_to_remove.append(client_socket)
                break
            print(f'Received message: {data.decode()}')

def start_server(port, certfile, keyfile):
    context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
    context.load_cert_chain(certfile=certfile, keyfile=keyfile)

    with socket.socket(socket.${proto_type}, socket.SOCK_STREAM) as server_socket:
        server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server_socket.bind(('0.0.0.0', port))
        server_socket.listen(20)
        print(f'Server listening on port {port}')

        while True:
            client_socket, client_address = server_socket.accept()
            tls_client_socket = context.wrap_socket(client_socket, server_side=True)
            client_thread = threading.Thread(target=handle_client, args=(client_socket, client_address))
            client_threads[client_socket] = client_thread
            client_thread.start()
            for to_remove_socket in clients_to_remove:
                client_threads[to_remove_socket].join()

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python tls_server.py <port> <certfile> <keyfile>")
        sys.exit(1)

    port = int(sys.argv[1])
    certfile = sys.argv[2]
    keyfile = sys.argv[3]
    start_server(port, certfile, keyfile)
EOF

  python3 "${srv_path}" "$port" "$cert_file" "$key_file"
  rm -f "${srv_path}"
}