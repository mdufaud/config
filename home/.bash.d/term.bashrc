#
# ANSI Escape Sequences
#

ANSI_UNICODE_ESCAPE="\u001b"
ANSI_HEX_ESCAPE="\x1B"
ANSI_DEC_ESCAPE="\27"
ANSI_OCTAL_ESCAPE="\033"

ANSI_ESCAPE="$ANSI_OCTAL_ESCAPE"
ANSI_CLOSE=""

ANSI_RESET="${ANSI_ESCAPE}[0m${ANSI_CLOSE}"
COLOR_DEFAULT="${ANSI_ESCAPE}[39m${ANSI_CLOSE}"

# 8 colors

BLACK="${ANSI_ESCAPE}[30m${ANSI_CLOSE}"
RED="${ANSI_ESCAPE}[31m${ANSI_CLOSE}"
GREEN="${ANSI_ESCAPE}[32m${ANSI_CLOSE}"
YELLOW="${ANSI_ESCAPE}[33m${ANSI_CLOSE}"
BLUE="${ANSI_ESCAPE}[34m${ANSI_CLOSE}"
MAGENTA="${ANSI_ESCAPE}[35m${ANSI_CLOSE}"
CYAN="${ANSI_ESCAPE}[36m${ANSI_CLOSE}"
WHITE="${ANSI_ESCAPE}[37m${ANSI_CLOSE}"

# 16 colors

BOLD_BLACK="${ANSI_ESCAPE}[30;1m${ANSI_CLOSE}"
BOLD_RED="${ANSI_ESCAPE}[0;31m${ANSI_CLOSE}"
BOLD_GREEN="${ANSI_ESCAPE}[32;1m${ANSI_CLOSE}"
BOLD_YELLOW="${ANSI_ESCAPE}[33;1m${ANSI_CLOSE}"
BOLD_BLUE="${ANSI_ESCAPE}[34;1m${ANSI_CLOSE}"
BOLD_MAGENTA="${ANSI_ESCAPE}[35;1m${ANSI_CLOSE}"
BOLD_CYAN="${ANSI_ESCAPE}[36;1m${ANSI_CLOSE}"
BOLD_WHITE="${ANSI_ESCAPE}[37;1m${ANSI_CLOSE}"

# Background 8 colors

BG_BLACK="${ANSI_ESCAPE}[40m${ANSI_CLOSE}"
BG_RED="${ANSI_ESCAPE}[41m${ANSI_CLOSE}"
BG_GREEN="${ANSI_ESCAPE}[42m${ANSI_CLOSE}"
BG_YELLOW="${ANSI_ESCAPE}[43m${ANSI_CLOSE}"
BG_BLUE="${ANSI_ESCAPE}[44m${ANSI_CLOSE}"
BG_MAGENTA="${ANSI_ESCAPE}[45m${ANSI_CLOSE}"
BG_CYAN="${ANSI_ESCAPE}[46m${ANSI_CLOSE}"
BG_WHITE="${ANSI_ESCAPE}[47m${ANSI_CLOSE}"

# Background 16 colors

BG_BOLD_BLACK="${ANSI_ESCAPE}[40;1m${ANSI_CLOSE}"
BG_BOLD_RED="${ANSI_ESCAPE}[41;1m${ANSI_CLOSE}"
BG_BOLD_GREEN="${ANSI_ESCAPE}[42;1m${ANSI_CLOSE}"
BG_BOLD_YELLOW="${ANSI_ESCAPE}[43;1m${ANSI_CLOSE}"
BG_BOLD_BLUE="${ANSI_ESCAPE}[44;1m${ANSI_CLOSE}"
BG_BOLD_MAGENTA="${ANSI_ESCAPE}[45;1m${ANSI_CLOSE}"
BG_BOLD_CYAN="${ANSI_ESCAPE}[46;1m${ANSI_CLOSE}"
BG_BOLD_WHITE="${ANSI_ESCAPE}[47;1m${ANSI_CLOSE}"

# 256 colors

ansi_color()
{
  echo -e "${ANSI_ESCAPE}[38;5;$1m${ANSI_CLOSE}"
}

ansi_bg()
{
  echo -e "${ANSI_ESCAPE}[48;5;$1m${ANSI_CLOSE}"
}

# Modifiers

BOLD="${ANSI_ESCAPE}[1m${ANSI_CLOSE}"
FAINT="${ANSI_ESCAPE}[2m${ANSI_CLOSE}"
ITALIC="${ANSI_ESCAPE}[3m${ANSI_CLOSE}"
UNDERLINE="${ANSI_ESCAPE}[4m${ANSI_CLOSE}"
BLINKING="${ANSI_ESCAPE}[5m${ANSI_CLOSE}"
REVERSED="${ANSI_ESCAPE}[7m${ANSI_CLOSE}"
HIDDEN="${ANSI_ESCAPE}[8m${ANSI_CLOSE}"
STRIKETHROUGH="${ANSI_ESCAPE}[9m${ANSI_CLOSE}"

## ANSI cursor control ##

cursor_move_up() { echo -e "${ANSI_ESCAPE}[$1A${ANSI_CLOSE}"; }
cursor_move_down() { echo -e "${ANSI_ESCAPE}[$1B${ANSI_CLOSE}"; }
cursor_move_right() { echo -e "${ANSI_ESCAPE}[$1C${ANSI_CLOSE}"; }
cursor_move_left() { echo -e "${ANSI_ESCAPE}[$1D${ANSI_CLOSE}"; }

line_move_down() { echo -e "${ANSI_ESCAPE}[$1E${ANSI_CLOSE}"; }
line_move_up() { echo -e "${ANSI_ESCAPE}[$1F${ANSI_CLOSE}"; }

cursor_move_col() { echo -e "${ANSI_ESCAPE}[$1G${ANSI_CLOSE}"; }
cursor_move_pos()
{
  local __row=$1
  local __col=$2
  echo -e "${ANSI_ESCAPE}[${__row};${__col}H${ANSI_CLOSE}"
}

cursor_save_pos() { echo -e "${ANSI_ESCAPE}[s${ANSI_CLOSE}"; }
cursor_restore_pos() { echo -e "${ANSI_ESCAPE}[u${ANSI_CLOSE}"; }

# ANSI erase functions

# from cursor to end of screen
clear_screen_to_end() { echo -e "${ANSI_ESCAPE}[0J${ANSI_CLOSE}"; }
# from cursor to beginning of screen
clear_screen_to_beg() { echo -e "${ANSI_ESCAPE}[1J${ANSI_CLOSE}"; }
# entire screen
clear_screen_all() { echo -e "${ANSI_ESCAPE}[2J${ANSI_CLOSE}"; }

# from cursor to end of line
clear_line_to_end() { echo -e "${ANSI_ESCAPE}[0K${ANSI_CLOSE}"; }
# from cursor to beginning of line
clear_line_to_beg() { echo -e "${ANSI_ESCAPE}[1K${ANSI_CLOSE}"; }
# entire line
clear_line_all() { echo -e "${ANSI_ESCAPE}[2K${ANSI_CLOSE}"; }