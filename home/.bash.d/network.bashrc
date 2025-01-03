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

 if ! is_shell_piped && bin_exists qrcode-terminal; then
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