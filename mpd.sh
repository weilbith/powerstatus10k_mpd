#!/bin/bash
#
# PowerStatus10k segment.
# This segment displays the current MPD status.

# Define a format string to show the current state.
# Use the icons and colors to display the state.
#
# Arguments:
#   $1 - state string
#
# Returns:
#   format string for the state
#
function getStateFormatString() {
  # Build the format string with the prefix to change the font color.
  formatString="%{F"

  # Choose the correct color and icon depending on the status.
  if [[ "$1" == "play" ]]; then
    formatString="${formatString}${MPD_COLOR_PLAY}}${MPD_ICON_PLAY}"

  elif [[ "$1" == "pause" ]]; then
    formatString="${formatString}${MPD_COLOR_PAUSE}}${MPD_ICON_PAUSE}"

  else
    formatString="${formatString}${MPD_COLOR_STOP}}${MPD_ICON_STOP}"
  fi

  # Finalize the format string and return.
  formatString="${formatString}%{F-}"
  echo "${formatString}"
}

# Interface

# Implement the interface function for the initial subscription state.
#
function initState_mpd() {
  # Start the subscribing python script.
  source_directory=$(dirname "${BASH_SOURCE[0]}")
  virtual_environment="$source_directory/venv"

  [[ ! -d "$virtual_environment" ]] && python3 -m venv "$virtual_environment"
  # shellcheck disable=SC1090
  source "$virtual_environment/bin/activate"
  pip install -r "$source_directory/requirements.txt"
  python3 "$source_directory/mpd_subscriber.py" &

  # Get current state if possible.
  if command -v mpc >/dev/null &&
    mpc >/dev/null 2>&1 &&
    [[ $(mpc | wc -l) -gt 1 ]]; then
    artist=$(mpc --format "%artist%" | head -n1)
    title=$(mpc --format "%title%" | head -n1)

    case "$(mpc | sed -n 2p)" in
    "[playing]"*)
      state="play"
      ;;

    "[paused]"*)
      state="pause"
      ;;

    *)
      state="stop"
      ;;
    esac

    format_mpd "${state}:${artist}:${title}"

  else
    # Only show the icon.
    STATE="${MPD_ICON_BASE}"
  fi
}

# Implement the interface function to format the current state of the subscription.
#
function format_mpd() {
  state="$(getStateFormatString "$(awk -F ':' '{print $1}' <<<"$1")")"
  artist=$(abbreviate "$(awk -F ':' '{print $2}' <<<"$1")" "mpd")
  title=$(abbreviate "$(awk -F ':' '{print $3}' <<<"$1")" "mpd")

  # shellcheck disable=SC2034
  STATE="${MPD_ICON_BASE} ${state} ${artist} - ${title}"
}
