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

is_pid_alive()
{
  _arg_assert_number "$1" "usage: is_pid_alive <pid>" || return

  ps -p $1 >/dev/null 2>&1
}

duh()
{
  du -h "$@" | sort -h
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
  _arg_assert_exists "$1" "usage: syslog_notice {debug,info,notice,warning,err,...} msg..." || return
  _arg_assert_exists "$2" "usage: syslog_notice {debug,info,notice,warning,err,...} msg..." || return

  local __facility="local0"
  local __priority=$1
  shift

  logger -p "$__facility.$__priority" -t "BASH" "$@"
}

function syslog_tail() {
  local __nb=${1:-10}
  tail /var/log/syslog -n ${__nb}
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
  _arg_assert_exists "$1" "usage: strace_signal [signal-name --] {pid,cmd} " || return

  local __signame=$1
  local __lines=$2

  if [ "$__lines" == "--" ]; then
    _arg_assert_exists "$3" "usage: strace_signal [signal-name --] {pid,cmd} " || return
    shift
    shift
  else
    __signame=all
  fi
                      # trace /    signal   / status / fds  / path / CMD or PID
  _strace_pid_or_cmd   '!all'   "$__signame"  'all'   'all'  'all'   "$@"
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

dbus_system_query()
{
  _arg_assert_exists "$1" "usage: dbus_system_query <service_name>" || return

  local service_name=$1
  local object_path="/${1//./\/}"
  dbus_system_call "$service_name" "$object_path" "org.freedesktop.DBus.Introspectable" "Introspect" | _prettify_dbus_introspection
}

dbus_session_query()
{
  _arg_assert_exists "$1" "usage: dbus_session_query <service_name>" || return

  local service_name=$1
  local object_path="/${1//./\/}"
  dbus_session_call "$service_name" "$object_path" "org.freedesktop.DBus.Introspectable" "Introspect" | _prettify_dbus_introspection
}

dbus_session_call()
{
  _dbus_call --session "$@"
}

dbus_system_call()
{
  _dbus_call --system "$@"
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