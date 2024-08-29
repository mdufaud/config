#
# Prompt
#

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
  if [ -x "$(command -v tput)" ] && tput setaf 1 >&/dev/null; then
      # We have color support; assume it's compliant with Ecma-48
      # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
      # a case would tend to support setf rather than setaf.)
      color_prompt=yes
  else
	    color_prompt=
  fi
fi

# Show only last X directories
PROMPT_DIRTRIM=4

EMOJI_CHECK=✅
EMOJI_CROSS=❌

build_prompt()
{
    local __user="\u"
    local __host="\h"
    local __path="\w"
    local __date="\t"

    local __virtual_env=""
    if is_empty "${VIRTUAL_ENV_DISABLE_PROMPT}"; then
        if ! is_empty "${VIRTUAL_ENV_PROMPT}"; then
            __virtual_env="${VIRTUAL_ENV_PROMPT} "
        elif ! is_empty "${VIRTUAL_ENV}"; then
            __virtual_env="($(basename ${VIRTUAL_ENV})) "
        fi
    fi

    if [ "$color_prompt" = yes ]; then
        # \[...\] tells bash that the enclosed characters won't take any space on the line
        local __cyan="\[${CYAN}\]"
        local __green="\[${GREEN}\]"
        local __bold_yellow="\[${BOLD_YELLOW}\]"
        local __end_color="\[${ANSI_RESET}\]"
        local __emoji_cmd_ret="if [ \$? = 0 ]; then echo \"${EMOJI_CHECK}\"; else echo \"${EMOJI_CROSS}\"; fi"

        # {emote} {user}@{host}:{path}$
        PS1="\`${__emoji_cmd_ret}\` ${__virtual_env}${__cyan}${__user}${__end_color}@${__green}${__host}${__end_color}:${__bold_yellow}${__path}${__end_color}\$ "
    else
        PS1="${__virtual_env}${__user}@${__host}:${__path}\$ "
    fi
}

PROMPT_COMMAND=build_prompt
