#
# Convert
#

# Converting audio and video files
function 2ogg() { eyeD3 --remove-all-images "$1"; local __fname="${1%.*}"; sox "$1" "$__fname.ogg"; }
function 2wav() { local __fname="${1%.*}"; ffmpeg -threads 0 -i "$1" "$__fname.wav"; }
function 2aif() { local __fname="${1%.*}"; ffmpeg -threads 0 -i "$1" "$__fname.aif"; }
function 2mp3() { local __fname="${1%.*}"; ffmpeg -threads 0 -i "$1" "$__fname.mp3"; }
function 2mov() { local __fname="${1%.*}"; ffmpeg -threads 0 -i "$1" "$__fname.mov"; }
function 2mp4() { local __fname="${1%.*}"; ffmpeg -threads 0 -i "$1" "$__fname.mp4"; }
function 2avi() { local __fname="${1%.*}"; ffmpeg -threads 0 -i "$1" "$__fname.avi"; }
function 2webm() { local __fname="${1%.*}"; ffmpeg -threads 0 -i "$1" -c:v libvpx "$__fname.webm"; }
function 2h265() { local __fname="${1%.*}"; ffmpeg -threads 0 -i "$1" -c:v libx265 "$__fname'_converted'.mp4"; }
function 2flv() { local __fname="${1%.*}"; ffmpeg -threads 0 -i "$1" "$__fname.flv"; }
function 2mpg() { local __fname="${1%.*}"; ffmpeg -threads 0 -i "$1" "$__fname.mpg"; }

# Converting documents and images

function 2txt() { soffice --headless txt "$1"; }
function 2pdf() {
  if [ ${1: -4} == ".html" ]
  then
    local __fname="${1%.*}"
    soffice --headless --convert-to odt "$1"
    soffice --headless pdf "$__fname.html"
  else
    soffice --headless pdf "$1"
  fi
}
function 2doc() { soffice --headless doc "$1"; }
function 2odt() { soffice --headless odt "$1"; }
function 2jpeg() { local __fname="${1%.*}"; convert "$1" "$__fname.jpg"; }
function 2jpg() { local __fname="${1%.*}"; convert "$1" "$__fname.jpg"; }
function 2png() { local __fname="${1%.*}"; convert "$1" "$__fname.png"; }
function 2bmp() { local __fname="${1%.*}"; convert "$1" "$__fname.bmp"; }
function 2tiff() { local __fname="${1%.*}"; convert "$1" "$__fname.tiff"; }
function 2gif() {
  _arg_assert_binary ffmpeg "No ffmpeg found" || return
  _arg_assert_binary convert "No convert found" || return

  opt_begin "2gif [-r fps] [-s scale] [-f fuzz] <file>"
  opt_desc  "Convert a video or image to GIF"
  opt_param r fps   10  "Frame rate"
  opt_param s scale 480 "Output height in px"
  opt_param f fuzz  2   "Color fuzz % for dithering"
  opt_parse "$@" || return

  local __input="${opt_args[0]}"
  _arg_assert_exists "$__input" "$opt_usage" || return

  local __fname="${__input%.*}"
  if [ ! -d "/tmp/gif" ]; then mkdir "/tmp/gif"; fi
  if [ "${__input: -4}" == ".mp4" ] || [ "${__input: -4}" == ".mov" ] || [ "${__input: -4}" == ".avi" ] || [ "${__input: -4}" == ".flv" ] || [ "${__input: -4}" == ".mpg" ] || [ "${__input: -4}" == ".webm" ]
  then
    ffmpeg -i "$__input" -r "$opt_fps" -vf "scale=trunc(oh*a/2)*2:${opt_scale}" /tmp/gif/out%04d.png
    convert -delay "1x${opt_fps}" "/tmp/gif/*.png" -fuzz "${opt_fuzz}%" +dither -coalesce -layers OptimizeTransparency +map "$__fname.gif"
  else
    convert "$__input" "$__fname.gif"
    rm "$__input"
  fi
  rm -r "/tmp/gif"
}