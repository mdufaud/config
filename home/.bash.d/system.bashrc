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

  echo $triplet | sed "s/android/gnu/g"
}

is_intel()
{
  [ "$(uname -m)" == "x86_64" ];
}

is_amd()
{
  [ "$(uname -m)" == "amd64" ];
}

is_arm()
{
  case $(uname -m) in
    aarch64) return 0;;
    arm64) return 0;;
    armv7) return 0;;
    *) return 1;;
  esac
}

get_triplet()
{
  local triplet=$(make -v | grep 'Built for' | awk '{print $3}')

  echo $triplet | sed "s/android/gnu/g"
}

get_windows_name()
{
  powershell.exe '$env:UserName' | tr -d '\r' | tr -d '\n'
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
    --syscall-times=us \
    --timestamps=time,us \
    --trace=$__trace \
    --signal=$__signal \
    --trace-fds=$__fds \
    --trace-path=$__path\
    --status=$__status"

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

strace_cred()
{
  _arg_assert_exists "$1" "usage: strace_cred {pid,cmd}" || return
                      # trace / signal / status / fds  / path / CMD or PID
  _strace_pid_or_cmd "%cred"   'all'    'all'   'all'  'all'   "$@"
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

#
# Dbus
#

dbus_list_services()
{
  dbus-send --system --dest=org.freedesktop.DBus --type=method_call --print-reply \
    /org/freedesktop/DBus org.freedesktop.DBus.ListNames | grep string | awk -F\" '{print $2}'
}

dbus_service_info()
{
  _arg_assert_exists "$1" "usage: dbus_service_info <service_name>" || return

  dbus-send --system --dest=org.freedesktop.DBus --type=method_call --print-reply \
    /org/freedesktop/DBus org.freedesktop.DBus.GetConnectionUnixProcessID \
    string:"$1"
}

dbus_call_method()
{
  _arg_assert_exists "$1" "usage: dbus_call_method <service_name> <object_path> <interface_name> <method_name> [args...]" || return
  _arg_assert_exists "$2" "usage: dbus_call_method <service_name> <object_path> <interface_name> <method_name> [args...]" || return
  _arg_assert_exists "$3" "usage: dbus_call_method <service_name> <object_path> <interface_name> <method_name> [args...]" || return
  _arg_assert_exists "$4" "usage: dbus_call_method <service_name> <object_path> <interface_name> <method_name> [args...]" || return

  local service_name=$1
  local object_path=$2
  local interface_name=$3
  local method_name=$4
  shift 4

  dbus-send --system --dest="$service_name" --type=method_call --print-reply \
    "$object_path" "$interface_name"."$method_name" "$@"
}

#
# NetworkManager
#

nm_list_devices()
{
  dbus_call_method org.freedesktop.NetworkManager /org/freedesktop/NetworkManager org.freedesktop.NetworkManager GetDevices
}

nm_device_info()
{
  _arg_assert_exists "$1" "usage: nm_device_info <device_path>" || return

  dbus_call_method org.freedesktop.NetworkManager "$1" org.freedesktop.DBus.Properties GetAll string:"org.freedesktop.NetworkManager.Device"
}

nm_list_connections()
{
  dbus_call_method org.freedesktop.NetworkManager /org/freedesktop/NetworkManager/Settings org.freedesktop.NetworkManager.Settings ListConnections
}

nm_connection_info()
{
  _arg_assert_exists "$1" "usage: nm_connection_info <connection_path>" || return

  dbus_call_method org.freedesktop.NetworkManager "$1" org.freedesktop.DBus.Properties GetAll string:"org.freedesktop.NetworkManager.Settings.Connection"
}

#
# Systemd
#

dbus_query_systemd()
{
  _arg_assert_exists "$1" "usage: dbus_query_systemd <method_name> [args...]" || return

  local method_name=$1
  shift

  dbus_call_method org.freedesktop.systemd1 /org/freedesktop/systemd1 org.freedesktop.systemd1.Manager "$method_name" "$@"
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
  dbus_call_method fi.w1.wpa_supplicant1 /fi/w1/wpa_supplicant1 org.freedesktop.DBus.Properties GetAll string:"fi.w1.wpa_supplicant1"
}

wpa_interface_info()
{
  _arg_assert_exists "$1" "usage: wpa_interface_info <interface_path>" || return

  dbus_call_method fi.w1.wpa_supplicant1 "$1" org.freedesktop.DBus.Properties GetAll string:"fi.w1.wpa_supplicant1.Interface"
}

wpa_list_networks()
{
  _arg_assert_exists "$1" "usage: wpa_list_networks <interface_path>" || return

  dbus_call_method fi.w1.wpa_supplicant1 "$1" org.freedesktop.DBus.Properties GetAll string:"fi.w1.wpa_supplicant1.Interface.Network"
}

wpa_network_info()
{
  _arg_assert_exists "$1" "usage: wpa_network_info <network_path>" || return

  dbus_call_method fi.w1.wpa_supplicant1 "$1" org.freedesktop.DBus.Properties GetAll string:"fi.w1.wpa_supplicant1.Network"
}