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

  local __fname="${1%.*}"
  if [ ! -d "/tmp/gif" ]; then mkdir "/tmp/gif"; fi
  if [ ${1: -4} == ".mp4" ] || [ ${1: -4} == ".mov" ] || [ ${1: -4} == ".avi" ] || [ ${1: -4} == ".flv" ] || [ ${1: -4} == ".mpg" ] || [ ${1: -4} == ".webm" ]
  then
    ffmpeg -i "$1" -r 10 -vf 'scale=trunc(oh*a/2)*2:480' /tmp/gif/out%04d.png
    convert -delay 1x10 "/tmp/gif/*.png" -fuzz 2% +dither -coalesce -layers OptimizeTransparency +map "$__fname.gif"
  else
    convert "$1" "$__fname.gif"
    rm "$1"
  fi
  rm -r "/tmp/gif"
}