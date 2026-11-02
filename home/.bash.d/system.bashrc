#!/bin/bash

#
# System
#

# pass options to free
alias sys_mem_info='free -h -l -t'

# get server cpu info
alias sys_cpu_info='lscpu'
# older system use /proc/cpuinfo
#alias cpuinfo='less /proc/cpuinfo'

# get GPU ram on desktop / laptop
alias sys_gpu_mem_info='grep -i --color memory /var/log/Xorg.0.log'

# get all hardware
alias sys_hardware="sudo lshw"

alias sys_gpu="lspci"

pid_alive()
{
  _arg_assert_number "$1" "usage: pid_alive <pid>" || return

  ps -p $1 >/dev/null 2>&1
}

pid_list()
{
  _arg_assert_exists "$1" "usage: pid_list <pid>" || return

  local pid ppid start cmd parent

  while IFS= read -r pid; do
    ppid=$(ps -p "$pid" -o ppid=) || continue
    ppid=${ppid//[[:space:]]/}
    [[ -n $ppid ]] || continue

    start=$(ps -p "$pid" -o lstart=)
    cmd=$(ps -p "$pid" -o args=)
    parent=$(ps -p "$ppid" -o args=)

    [[ -n $cmd ]] &&
      printf 'PID %s <- PPID %s | %s | CMD %s | PARENT %s\n' \
        "$pid" "$ppid" "$start" "$cmd" "$parent"
  done < <(pgrep -f "$1")
}

duh()
{
  du -h "$@" | sort -h
}

psg()
{
  ps aux | grep "$@" | grep -v grep
}

#
# OS
#

__check_os_id()
(
  if [ ! -r "/etc/os-release" ]; then
    return 1
  fi
  source /etc/os-release
  [ "$ID" == "$1" ];
)

is_ubuntu()
{
  __check_os_id "ubuntu"
}

is_debian()
{
  __check_os_id "debian"
}

is_archlinux()
{
  __check_os_id "arch"
}

is_termux()
{
  bin_exists termux-setup-storage
}

is_osx()
{
  [[ "$(uname)" == 'Darwin' ]];
}

is_wsl()
{
  [ -f /proc/version ] && [[ $(grep -i Microsoft /proc/version) ]];
}

is_x11()
{
  [[ "${XDG_SESSION_TYPE}" = "x11" ]];
}

is_wayland()
{
  [[ "${XDG_SESSION_TYPE}" = "wayland" ]];
}

os_get_triplet()
{
  local triplet=$(make -v | grep 'Built for' | awk '{print $3}')

  sed "s/android/gnu/g" <<< "${triplet}"
}

is_intel()
{
  lscpu | grep -q 'Vendor ID:.*GenuineIntel'
}

is_amd()
{
  lscpu | grep -q 'Vendor ID:.*AuthenticAMD'
}

is_arm()
{
  case "$(uname -m)" in
    aarch64|arm64|armv7*|armv6*|armhf|armel) return 0;;
    *) return 1;;
  esac
}

get_triplet()
{
  local triplet=$(make -v | grep 'Built for' | awk '{print $3}')

  sed "s/android/gnu/g" <<< "${triplet}"
}

get_windows_name()
{
  if is_wsl; then
    powershell.exe '$env:UserName' | tr -d '\r' | tr -d '\n'
  fi
}

#
# CRT
#

os_install_crt()
{
  if [ -d "/etc/ca-certificates/trust-source/anchors" ]; then
    if ! sudo trust anchor --store "$1"; then
      sudo cp "$1" /etc/ca-certificates/trust-source/anchors
      sudo update-ca-trust
    fi
  elif [ -d "/usr/local/share/ca-certificates/" ]; then
    sudo cp "$1" /usr/local/share/ca-certificates/
    sudo update-ca-certificates
  else
    return 1
  fi
}


#
# Drive
#

alias disk_swap_clear="sudo swapoff -a && sudo swapon -a"
alias mount_pretty="mount | column -t"
alias mountp="mount_pretty"

#
# Syslog
#

function syslog_msg() {
  opt_begin "syslog_msg [-f facility] [-t tag] <priority> <msg...>"
  opt_desc  "Send a message to syslog"
  opt_param f facility local0 "Syslog facility"
  opt_param t tag      BASH   "Syslog tag"
  opt_parse "$@" || return

  local __priority="${opt_args[0]}"
  _arg_assert_exists "$__priority" "$opt_usage" || return

  local __msg="${opt_args[*]:1}"
  _arg_assert_exists "$__msg" "$opt_usage" || return

  logger -p "$opt_facility.$__priority" -t "$opt_tag" "$__msg"
}

function syslog_tail() {
  local __nb=${1:-10}
  tail /var/log/syslog -n ${__nb}
}

#
# Lsof
#

# List open files by a specific user
lsof_user()
{
  _arg_assert_exists "$1" "usage: lsof_user <username>" || return

  lsof -u "$1"
}

# List open files for a given PID
lsof_pid()
{
  _arg_assert_number "$1" "usage: lsof_pid <pid>" || return

  lsof -p "$1"
}

# List open files for a given command name
lsof_cmd()
{
  _arg_assert_exists "$1" "usage: lsof_cmd <command_name>" || return

  lsof -c "$1"
}

# List processes listening on a specific port
lsof_port()
{
  _arg_assert_number "$1" "usage: lsof_port <port>" || return

  lsof -i :"$1"
}

# List all network connections (TCP + UDP)
lsof_network()
{
  lsof -i -P -n
}

# List only TCP connections
lsof_tcp()
{
  lsof -i TCP -P -n
}

# List only UDP connections
lsof_udp()
{
  lsof -i UDP -P -n
}

# List established TCP connections
lsof_established()
{
  lsof -i TCP -s TCP:ESTABLISHED -P -n
}

# List listening sockets
lsof_listen()
{
  lsof -i -s TCP:LISTEN -P -n
}

# List connections to a specific host
lsof_host()
{
  _arg_assert_exists "$1" "usage: lsof_host <host_or_ip>" || return

  lsof -i @"$1" -P -n
}

# List connections between local and remote host:port
lsof_host_port()
{
  _arg_assert_exists "$1" "usage: lsof_host_port <host_or_ip> <port>" || return
  _arg_assert_number "$2" "usage: lsof_host_port <host_or_ip> <port>" || return

  lsof -i @"$1":"$2" -P -n
}

# List IPv4 only connections
lsof_ipv4()
{
  lsof -i 4 -P -n
}

# List IPv6 only connections
lsof_ipv6()
{
  lsof -i 6 -P -n
}

# List open files in a specific directory (and below)
lsof_dir()
{
  _arg_assert_exists "$1" "usage: lsof_dir <directory>" || return

  lsof +D "$1"
}

# List who is using a specific file
lsof_file()
{
  _arg_assert_file "$1" "usage: lsof_file <file>" || return

  lsof "$1"
}

# List deleted but still open files (zombie files eating disk space)
lsof_deleted()
{
  lsof +L1
}

# List open files on a specific filesystem / mount point
lsof_mount()
{
  _arg_assert_exists "$1" "usage: lsof_mount <mount_point>" || return

  lsof +f -- "$1"
}

# List open unix domain sockets
lsof_unix()
{
  lsof -U
}

# Count open file descriptors per process, sorted
lsof_fd_count()
{
  lsof -n 2>/dev/null | awk '{print $1}' | sort | uniq -c | sort -rn | head -n "${1:-20}"
}

# List open files for current shell's PID
lsof_self()
{
  lsof -p $$
}

#
# Strace
#

_strace_pid_or_cmd()
{
  local __trace=$1
  shift
  local __signal=$1
  shift
  local __status=$1
  shift
  local __fds=$1
  shift
  local __path=$1
  shift
  local __pid=$1

  #-ff = --follow-forks --output-separately
  local __cmd="strace \
    -ff \
    -ttt \
    -T \
    -e trace=$__trace \
    -e signal=$__signal"

  if [ -n "$__pid" ] && arg_is_number "$__pid"; then
    # attach pid
    sudo $__cmd -p $__pid
  else
    # launch cmd
    $__cmd "$@"
  fi
}

strace_signal()
{
  opt_begin "strace_signal [-s signal] <pid|cmd> [args...]"
  opt_desc  "Trace signals delivered to a process"
  opt_param s signal all "Signal name to filter"
  opt_parse "$@" || return

  _arg_assert_exists "${opt_args[0]}" "$opt_usage" || return
  _strace_pid_or_cmd '!all' "$opt_signal" 'all' 'all' 'all' "${opt_args[@]}"
}

strace_syscall()
{
  _arg_assert_exists "$1" "usage: strace_syscall <syscall-name> {pid,cmd}" || return
  _arg_assert_exists "$2" "usage: strace_syscall <syscall-name> {pid,cmd}" || return

  local __syscall=$1
  shift
                      # trace     / signal / status / fds  / path / CMD or PID
  _strace_pid_or_cmd   $__syscall   '!all'   'all'   'all'  'all'   "$@"
}

strace_network()
{
  _arg_assert_exists "$1" "usage: strace_network {pid,cmd}" || return
                      # trace / signal / status / fds  / path / CMD or PID
  _strace_pid_or_cmd "%network" 'all'    'all'   'all'  'all'   "$@"
}

strace_process()
{
  _arg_assert_exists "$1" "usage: strace_process {pid,cmd}" || return
                      # trace / signal / status / fds  / path / CMD or PID
  _strace_pid_or_cmd "%process" 'all'    'all'   'all'  'all'   "$@"
}

strace_memory()
{
  _arg_assert_exists "$1" "usage: strace_memory {pid,cmd}" || return
                      # trace / signal / status / fds  / path / CMD or PID
  _strace_pid_or_cmd "%memory" 'all'    'all'   'all'  'all'   "$@"
}

strace_ipc()
{
  _arg_assert_exists "$1" "usage: strace_ipc {pid,cmd}" || return
                      # trace / signal / status / fds  / path / CMD or PID
  _strace_pid_or_cmd "%ipc"     'all'    'all'   'all'  'all'   "$@"
}

# Capabilities, setuid and so on
strace_cred()
{
  _arg_assert_exists "$1" "usage: strace_cred {pid,cmd}" || return
                      # trace / signal / status / fds  / path / CMD or PID
  _strace_pid_or_cmd "%creds"   'all'    'all'   'all'  'all'   "$@"
}

strace_stat()
{
  _arg_assert_exists "$1" "usage: strace_stat {pid,cmd}" || return
                      # trace / signal / status / fds  / path / CMD or PID
  _strace_pid_or_cmd "%stat"   'all'    'all'   'all'  'all'   "$@"
}

strace_clock()
{
  _arg_assert_exists "$1" "usage: strace_clock {pid,cmd}" || return
                      # trace / signal / status / fds  / path / CMD or PID
  _strace_pid_or_cmd "%clock"   'all'    'all'   'all'  'all'   "$@"
}

# File descriptors
strace_desc()
{
  _arg_assert_exists "$1" "usage: strace_desc {pid,cmd}" || return
                      # trace / signal / status / fds  / path / CMD or PID
  _strace_pid_or_cmd "%desc"   'all'    'all'   'all'  'all'   "$@"
}

strace_file()
{
  _arg_assert_exists "$1" "usage: strace_file {pid,cmd}" || return
                      # trace / signal / status / fds  / path / CMD or PID
  _strace_pid_or_cmd "%file"   'all'    'all'   'all'  'all'   "$@"
}

strace_summary()
{
  _arg_assert_exists "$1" "usage: strace_summary <cmd>" || return
  strace -c "$@"
}

strace_stack()
{
  _arg_assert_exists "$1" "usage: strace_stack <cmd>" || return
  strace -k "$@"
}

strace_inject_error()
(
  _arg_assert_exists "$1" "usage: strace_inject_error <cmd>" || return

 ## ---- STEP 1: Select the System Call ----

  # Dictionary of syscalls we want to test, with their descriptions
  declare -A syscall_dict=(
    [write]="Write data (e.g., to a file or socket)"
    [openat]="Open or create a file"
    [connect]="Initiate a network connection (TCP, UDP)"
    [read]="Read data (e.g., from a file or socket)"
    [mkdir]="Create a directory"
  )

  local syscall
  syscall=$(printf "%s\n" "${!syscall_dict[@]}" | fzf --height 25% --layout=reverse \
    --prompt="Select a syscall to intercept > ")

  # Exit if the user cancelled (pressed Esc)
  [ -z "$syscall" ] && return

  ## ---- STEP 2: Select the Error based on the Syscall ----

  # Dynamically build the dictionary of possible errors
  declare -A error_dict
  case "$syscall" in
    write)
      error_dict=(
        [ENOSPC]="No space left on device"
        [EIO]="I/O error (e.g., failing disk)"
        [EDQUOT]="Disk quota exceeded"
      )
      ;;
    openat)
      error_dict=(
        [ENOENT]="No such file or directory"
        [EACCES]="Permission denied"
        [EMFILE]="Too many open files by the process"
      )
      ;;
    connect)
      error_dict=(
        [ECONNREFUSED]="Connection refused by the server"
        [ETIMEDOUT]="Connection timed out"
        [EHOSTUNREACH]="No route to host"
      )
      ;;
    read)
      error_dict=(
        [EIO]="I/O error"
        [EBADF]="Bad file descriptor"
      )
      ;;
    mkdir)
      error_dict=(
        [EEXIST]="Directory already exists"
        [EACCES]="Permission denied"
        [ENOSPC]="No space left on device"
      )
      ;;
    *)
      echo "No predefined error list for '$syscall'." >&2
      return 1
      ;;
  esac

  # The rest is the same, but uses the dictionary we just created
  local error_preview_command='case $0 in'
  for code in "${!error_dict[@]}"; do
    error_preview_command+=" ${code}) echo \"${error_dict[$code]}\" ;;"
  done
  error_preview_command+=' esac'

  local error
  error=$(printf "%s\n" "${!error_dict[@]}" | fzf --height 25% --layout=reverse \
    --prompt="Select an error to inject into '$syscall' > " \
    --preview="bash -c '$error_preview_command' {}")

  [ -z "$error" ] && return

  # TODO add delay + signal with gum multi select

  ## ---- Optional Call Count Filter ----
  
  local count_clause=""
  if gum confirm "Add a filter based on the call count?"; then
    local input
    input=$(gum input --placeholder "Count: exact || from+ || from+step || first..end+step")
    if [ -n "$input" ]; then
      count_clause=":when=$input"
    fi
  fi

  ## ---- Execution ----
  
  local injection_expression="inject=$syscall:error=$error$count_clause"
  
  set -x # Debug
  strace -e "$injection_expression" "$@"
)

#
# Dbus
#

dbus_system_list()
{
  dbus_system_call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus ListNames \
    | grep string | awk -F\" '{print $2}'
}

dbus_session_list()
{
  dbus_session_call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus ListNames \
    | grep string | awk -F\" '{print $2}'
}

dbus_system_connection()
{
  _arg_assert_exists "$1" "usage: dbus_system_connection <service_name>" || return 1

  local service_name=$1
  local reply
  reply=$(dbus-send --system --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus "org.freedesktop.DBus.GetNameOwner" string:"$service_name" 2>&1)

  # Check for errors and exit if found
  if [[ "$reply" == *"Error"* ]]; then
    echo >&2 "Error resolving '$service_name': $reply"
    return 1
  fi

  # Parse and print the connection name to standard output
  echo "$reply" | grep "string" | awk -F '"' '{print $2}'
}

dbus_session_connection()
{
  _arg_assert_exists "$1" "usage: dbus_session_connection <service_name>" || return 1

  local service_name=$1
  local reply
  reply=$(dbus-send --session --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus "org.freedesktop.DBus.GetNameOwner" string:"$service_name" 2>&1)

  # Check for errors and exit if found
  if [[ "$reply" == *"Error"* ]]; then
    echo >&2 "Error resolving '$service_name': $reply"
    return 1
  fi

  # Parse and print the connection name to standard output
  echo "$reply" | grep "string" | awk -F '"' '{print $2}'
}

_prettify_dbus_introspection() {
  awk '
  /<\/interface>/ { in_interface=0 } # Reset when an interface block ends
  /<interface name=/ {
    match($0, /name="([^"]+)"/, arr);
    printf "\n🔷 \033[1;34mINTERFACE:\033[0m %s\n", arr[1];
    in_interface=1;
  }
  /<method name=/ {
    if (in_interface) {
      match($0, /name="([^"]+)"/, arr);
      printf "  ➡️  \033[1;33mMETHOD:\033[0m %s\n", arr[1];
    }
  }
  /<arg / {
    # Extract attributes, handling cases where one might be missing
    type = name = dir = "n/a";
    if (match($0, /type="([^"]+)"/, arr))   { type = arr[1]; }
    if (match($0, /name="([^"]+)"/, arr))   { name = arr[1]; }
    if (match($0, /direction="([^"]+)"/, arr)) { dir = arr[1]; }

    printf "    - \033[32mARG:\033[0m type=%-12s direction=%-5s name=%s\n", type, dir, name;
  }
  '
}

dbus_system_introspect()
{
  _arg_assert_exists "$1" "usage: dbus_system_introspect <service_name>" || return

  local service_name=$1
  local object_path="/${1//./\/}"
  dbus_system_call "$service_name" "$object_path" "org.freedesktop.DBus.Introspectable" "Introspect" | _prettify_dbus_introspection
}

dbus_session_introspect()
{
  _arg_assert_exists "$1" "usage: dbus_session_introspect <service_name>" || return

  local service_name=$1
  local object_path="/${1//./\/}"
  dbus_session_call "$service_name" "$object_path" "org.freedesktop.DBus.Introspectable" "Introspect" | _prettify_dbus_introspection
}

_dbus_call()
{
  _arg_assert_exists "$1" "usage: _dbus_call <bus_type> <service_name> <object_path> <interface_name> <method_name> [args...]" || return
  _arg_assert_exists "$2" "usage: _dbus_call <bus_type> <service_name> <object_path> <interface_name> <method_name> [args...]" || return
  _arg_assert_exists "$3" "usage: _dbus_call <bus_type> <service_name> <object_path> <interface_name> <method_name> [args...]" || return
  _arg_assert_exists "$4" "usage: _dbus_call <bus_type> <service_name> <object_path> <interface_name> <method_name> [args...]" || return
  _arg_assert_exists "$5" "usage: _dbus_call <bus_type> <service_name> <object_path> <interface_name> <method_name> [args...]" || return


  local bus_type
  if [ "$1" == "--system" ] || [ "$1" == "--session" ]; then
    bus_type="$1"
  else
    echo "Error: bus_type must be '--system' or '--session'" >&2
    return 1
  fi
  shift

  local service_name=$1
  local object_path=$2
  local interface_name=$3
  local method_name=$4
  shift 4

  dbus-send "$bus_type" --dest="$service_name" --type=method_call --print-reply \
    "$object_path" "$interface_name"."$method_name" "$@"
}

dbus_session_call()
{
  _dbus_call --session "$@"
}

dbus_system_call()
{
  _dbus_call --system "$@"
}

#
# NetworkManager
#

nm_list_devices()
{
  dbus_system_call org.freedesktop.NetworkManager /org/freedesktop/NetworkManager org.freedesktop.NetworkManager GetDevices
}

nm_device_info()
{
  _arg_assert_exists "$1" "usage: nm_device_info <device_path>" || return

  dbus_system_call org.freedesktop.NetworkManager "$1" org.freedesktop.DBus.Properties GetAll string:"org.freedesktop.NetworkManager.Device"
}

nm_list_connections()
{
  dbus_system_call org.freedesktop.NetworkManager /org/freedesktop/NetworkManager/Settings org.freedesktop.NetworkManager.Settings ListConnections
}

nm_connection_info()
{
  _arg_assert_exists "$1" "usage: nm_connection_info <connection_path>" || return

  dbus_system_call org.freedesktop.NetworkManager "$1" org.freedesktop.DBus.Properties GetAll string:"org.freedesktop.NetworkManager.Settings.Connection"
}

#
# Systemd
#

dbus_query_systemd()
{
  _arg_assert_exists "$1" "usage: dbus_query_systemd <method_name> [args...]" || return

  local method_name=$1
  shift

  dbus_system_call org.freedesktop.systemd1 /org/freedesktop/systemd1 org.freedesktop.systemd1.Manager "$method_name" "$@"
}

systemd_list_units()
{
  dbus_query_systemd ListUnits
}

systemd_list_jobs()
{
  dbus_query_systemd ListJobs
}

#
# wpa_supplicant
#

wpa_list_interfaces()
{
  dbus_system_call fi.w1.wpa_supplicant1 /fi/w1/wpa_supplicant1 org.freedesktop.DBus.Properties GetAll string:"fi.w1.wpa_supplicant1"
}

wpa_interface_info()
{
  _arg_assert_exists "$1" "usage: wpa_interface_info <interface_path>" || return

  dbus_system_call fi.w1.wpa_supplicant1 "$1" org.freedesktop.DBus.Properties GetAll string:"fi.w1.wpa_supplicant1.Interface"
}

wpa_list_networks()
{
  _arg_assert_exists "$1" "usage: wpa_list_networks <interface_path>" || return

  dbus_system_call fi.w1.wpa_supplicant1 "$1" org.freedesktop.DBus.Properties GetAll string:"fi.w1.wpa_supplicant1.Interface.Network"
}

wpa_network_info()
{
  _arg_assert_exists "$1" "usage: wpa_network_info <network_path>" || return

  dbus_system_call fi.w1.wpa_supplicant1 "$1" org.freedesktop.DBus.Properties GetAll string:"fi.w1.wpa_supplicant1.Network"
}

#
# Tmp cleaning
#

cache_clean_tmp()
{
  opt_begin "cache_clean_tmp [-n] [-H hours] [days]"
  opt_desc "Delete own entries unused for more than <days> day(s) or <hours> hour(s) (-H wins) from a tmpfs root (default /tmp, CACHE_CLEAN_ROOT to override)"
  opt_flag n dryrun "Dry run: only list candidates"
  opt_param H hours "" "Max age in hours, overrides days"
  opt_parse "$@" || return

  if [ "${#opt_args[@]}" -gt 1 ]; then
    print_err "cache_clean_tmp: too many arguments (options go before days)"
    return 1
  fi

  local days="${opt_args[0]:-1}"
  _arg_assert_number "$days" "usage: cache_clean_tmp [-n] [-H hours] [days=1]" || return
  if ! [[ "$days" =~ ^[0-9]+$ ]] || [ "$days" -lt 1 ]; then
    print_err "days must be an integer >= 1"
    return 1
  fi

  local hours=$(( days * 24 ))
  if [ -n "$opt_hours" ]; then
    if ! [[ "$opt_hours" =~ ^[0-9]+$ ]] || [ "$opt_hours" -lt 1 ]; then
      print_err "hours must be an integer >= 1"
      return 1
    fi
    hours="$opt_hours"
  fi

  local root="${CACHE_CLEAN_ROOT:-/tmp}"
  if [[ "$root" != /* ]]; then
    print_err "CACHE_CLEAN_ROOT must be an absolute path"
    return 1
  fi
  root=$(readlink -f -- "$root" 2>/dev/null)
  if [ ! -d "$root" ] || [ "$root" = "/" ]; then
    print_err "CACHE_CLEAN_ROOT must resolve to a directory other than /"
    return 1
  fi
  if [[ "$root" == *[\*\?\[]* ]]; then
    print_err "CACHE_CLEAN_ROOT must not contain glob characters"
    return 1
  fi
  if [ "$(findmnt -no FSTYPE -T "$root" 2>/dev/null | head -n1)" != "tmpfs" ]; then
    print_err "CACHE_CLEAN_ROOT must be on a tmpfs"
    return 1
  fi

  local now cutoff atime_cutoff
  now=$(date +%s)
  cutoff=$(( now - hours * 3600 ))
  atime_cutoff=$(( now - 2 * hours * 3600 ))

  local open_list mount_list
  open_list=$(find /proc/[0-9]*/fd /proc/[0-9]*/cwd -lname "$root/*" -printf '%l\n' 2>/dev/null)
  mount_list=$(printf '%b' "$(findmnt -rno TARGET)")

  local entry path out rc bytes n=0 freed=0
  local candidates=() sizes=()

  while IFS= read -r -d '' entry; do
    case "${entry##*/}" in
      .X11-unix|.ICE-unix|.font-unix|.XIM-unix|.Test-unix|.X*-lock|systemd-*|snap-private-tmp) continue ;;
    esac

    while IFS= read -r path; do
      [[ "$path" == "$entry" || "$path" == "$entry"/* ]] && continue 2
    done <<< "$open_list"

    while IFS= read -r path; do
      [[ "$path" == "$entry" || "$path" == "$entry"/* ]] && continue 2
    done <<< "$mount_list"

    out=$(find "$entry" \( -newermt "@$cutoff" -o -type f -newerat "@$atime_cutoff" -o -type s -o -type p \) -print -quit 2>/dev/null)
    rc=$?
    [ -n "$out" ] && continue
    [ "$rc" -ne 0 ] && continue

    read -r bytes _ < <(du -sb -- "$entry" 2>/dev/null)
    [[ "$bytes" =~ ^[0-9]+$ ]] || bytes=0
    candidates+=("$entry")
    sizes+=("$bytes")
    freed=$(( freed + bytes ))
    printf '%s\t%s\n' "$(numfmt --to=iec --suffix=B "$bytes")" "$entry"
    n=$(( n + 1 ))
  done < <(find "$root" -mindepth 1 -maxdepth 1 -user "$(id -un)" -mmin +$(( hours * 60 )) -print0 2>/dev/null)

  if [ "$opt_dryrun" == "true" ]; then
    printf 'cache_clean_tmp (dry-run): %d candidate(s), %s\n' "$n" "$(numfmt --to=iec --suffix=B "$freed")"
    return 0
  fi

  local i removed=0 really_freed=0
  open_list=$(find /proc/[0-9]*/fd /proc/[0-9]*/cwd -lname "$root/*" -printf '%l\n' 2>/dev/null)

  for i in "${!candidates[@]}"; do
    entry=${candidates[$i]}

    while IFS= read -r path; do
      if [[ "$path" == "$entry" || "$path" == "$entry"/* ]]; then
        printf 'skipped (opened): %s\n' "$entry"
        continue 2
      fi
    done <<< "$open_list"

    [ -L "$entry" ] || [ -e "$entry" ] || continue
    if [ "$(stat -c %Y "$entry" 2>/dev/null || echo 0)" -ge "$cutoff" ]; then
      printf 'skipped (active): %s\n' "$entry"
      continue
    fi

    if rm -rf --one-file-system -- "$entry"; then
      removed=$(( removed + 1 ))
      really_freed=$(( really_freed + sizes[$i] ))
    else
      printf 'failed: %s\n' "$entry"
    fi
  done

  printf 'cache_clean_tmp: %d/%d removed, %s freed\n' "$removed" "$n" "$(numfmt --to=iec --suffix=B "$really_freed")"
}

#
# Tool caches cleaning
#

_cache_clean_files()
{
  local label="$1" dir="$2" mins="$3" dryrun="$4" priv="${5:-}" depth="${6:-}"
  [ -d "$dir" ] || return 0

  local runner=() depth_args=()
  [ "$priv" == "sudo" ] && runner=(sudo)
  [ -n "$depth" ] && depth_args=(-maxdepth "$depth")

  local n bytes
  read -r n bytes < <(find "$dir" "${depth_args[@]}" -type f -amin +"$mins" -mmin +"$mins" -printf '%s\n' 2>/dev/null \
    | awk '{ n++; s += $1 } END { print n + 0, s + 0 }')

  if [ "$dryrun" != "true" ] && [ "$n" -gt 0 ]; then
    "${runner[@]}" find "$dir" "${depth_args[@]}" -type f -amin +"$mins" -mmin +"$mins" -delete 2>/dev/null
    [ -z "$depth" ] && "${runner[@]}" find "$dir" -mindepth 1 -type d -empty -delete 2>/dev/null
  fi

  __cache_clean_total=$(( __cache_clean_total + bytes ))
  printf '%-12s %6d file(s), %s\n' "$label" "$n" "$(numfmt --to=iec --suffix=B "$bytes")"
}

_cache_clean_units()
{
  local label="$1" dir="$2" mins="$3" dryrun="$4"
  [ -d "$dir" ] || return 0

  local unit bytes n=0 total=0
  while IFS= read -r -d '' unit; do
    [ -n "$(find "$unit" \( -mmin -"$mins" -o \( -type f -amin -"$mins" \) \) -print -quit 2>/dev/null)" ] && continue
    read -r bytes _ < <(du -sb -- "$unit" 2>/dev/null)
    [[ "$bytes" =~ ^[0-9]+$ ]] || bytes=0
    [ "$dryrun" == "true" ] || rm -rf --one-file-system -- "$unit"
    n=$(( n + 1 ))
    total=$(( total + bytes ))
  done < <(find "$dir" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)

  __cache_clean_total=$(( __cache_clean_total + total ))
  printf '%-12s %6d dir(s),  %s\n' "$label" "$n" "$(numfmt --to=iec --suffix=B "$total")"
}

_cache_clean_cmd()
{
  local label="$1" dryrun="$2"
  shift 2
  if [ "$dryrun" == "true" ]; then
    printf '%-12s would run: %s\n' "$label" "$*"
  else
    printf '%-12s %s\n' "$label" "$*"
    "$@"
  fi
}

cache_clean()
{
  opt_begin "cache_clean [-n] [-s] [days]"
  opt_desc "Prune tool caches (ccache, npm, yarn, pip, uv, cargo, docker builder, yay, vcpkg, pacman) unused for more than <days> day(s) (default 30)"
  opt_flag n dryrun "Dry run: only report what would be removed"
  opt_flag s sudo "Also clean the root-owned pacman cache (uses sudo)"
  opt_parse "$@" || return

  if [ "${#opt_args[@]}" -gt 1 ]; then
    print_err "cache_clean: too many arguments (options go before days)"
    return 1
  fi

  local days="${opt_args[0]:-30}"
  _arg_assert_number "$days" "usage: cache_clean [-n] [-s] [days=30]" || return
  if ! [[ "$days" =~ ^[0-9]+$ ]] || [ "$days" -lt 1 ]; then
    print_err "days must be an integer >= 1"
    return 1
  fi

  local mins=$(( days * 1440 ))
  local cache_home="${XDG_CACHE_HOME:-$HOME/.cache}"
  local __cache_clean_total=0 dir

  command -v ccache >/dev/null 2>&1 && _cache_clean_cmd ccache "$opt_dryrun" ccache --evict-older-than "${days}d"

  if command -v npm >/dev/null 2>&1; then
    dir=$(npm config get cache 2>/dev/null)
    _cache_clean_files npm "${dir}/_cacache" "$mins" "$opt_dryrun"
  fi

  if command -v yarn >/dev/null 2>&1; then
    dir=$(yarn cache dir 2>/dev/null | head -n1)
    [ -n "$dir" ] && _cache_clean_units yarn "$dir" "$mins" "$opt_dryrun"
  fi

  if command -v pip >/dev/null 2>&1; then
    dir=$(pip cache dir 2>/dev/null | head -n1)
    [ -n "$dir" ] && _cache_clean_files pip "$dir" "$mins" "$opt_dryrun"
  fi

  command -v uv >/dev/null 2>&1 && _cache_clean_cmd uv "$opt_dryrun" uv cache prune

  _cache_clean_files cargo "${CARGO_HOME:-$HOME/.cargo}/registry/cache" "$mins" "$opt_dryrun"

  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    _cache_clean_cmd docker "$opt_dryrun" docker builder prune -f --filter "until=$(( days * 24 ))h"
  fi

  command -v yay >/dev/null 2>&1 && _cache_clean_units yay "${cache_home}/yay" "$mins" "$opt_dryrun"

  local vcpkg_root="${VCPKG_ROOT:-}"
  if [ -z "$vcpkg_root" ] && command -v vcpkg >/dev/null 2>&1; then
    vcpkg_root=$(dirname "$(readlink -f "$(command -v vcpkg)")")
  fi
  if [ -d "$vcpkg_root/buildtrees" ]; then
    _cache_clean_files vcpkg-bin "${VCPKG_DEFAULT_BINARY_CACHE:-${cache_home}/vcpkg/archives}" "$mins" "$opt_dryrun"
    _cache_clean_files vcpkg-dl "${VCPKG_DOWNLOADS:-${vcpkg_root}/downloads}" "$mins" "$opt_dryrun" "" 1
    _cache_clean_units vcpkg-build "${vcpkg_root}/buildtrees" "$mins" "$opt_dryrun"
    _cache_clean_units vcpkg-pkg "${vcpkg_root}/packages" "$mins" "$opt_dryrun"
  fi

  if [ -d /var/cache/pacman/pkg ]; then
    if [ "$opt_sudo" == "true" ] || [ "$opt_dryrun" == "true" ]; then
      _cache_clean_files pacman /var/cache/pacman/pkg "$mins" "$opt_dryrun" sudo
    else
      printf '%-12s skipped (needs -s)\n' pacman
    fi
  fi

  if [ "$opt_dryrun" == "true" ]; then
    printf 'cache_clean (dry-run): %s measurable\n' "$(numfmt --to=iec --suffix=B "$__cache_clean_total")"
  else
    printf 'cache_clean: %s freed (excluding ccache/uv/docker, not measurable)\n' "$(numfmt --to=iec --suffix=B "$__cache_clean_total")"
  fi
}