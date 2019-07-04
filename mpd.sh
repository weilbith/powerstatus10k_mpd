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
    formatString+="${MPD_COLOR_PLAY}}${MPD_ICON_PLAY}"

  elif [[ "$1" == "pause" ]]; then
    formatString+="${MPD_COLOR_PAUSE}}${MPD_ICON_PAUSE}"
  fi

  # Finalize the format string and return.
  formatString+="%{F-}"
  echo "${formatString}"
}

# Starting the Python script to subscribe for changes.
# This will setup a Python virtual environment if it does not exist already.
# This installs or update the Python dependencies
#
function startSubscriber() {
  source_directory=$(dirname "${BASH_SOURCE[0]}")
  virtual_environment="$source_directory/venv"

  [[ ! -d "$virtual_environment" ]] && python3 -m venv "$virtual_environment"
  # shellcheck disable=SC1090
  source "$virtual_environment/bin/activate"
  pip install -r "$source_directory/requirements.txt"
  python3 "$source_directory/mpd_subscriber.py" &
}

# Check if the MPD daemon is running and active.
# Do not work it the MPC tool is not installed.
#
# Returns:
#   1 if active else 0
#
function isMpdActive() {
  if command -v mpc >/dev/null && # MPC is installed
    mpc >/dev/null 2>&1 && # MPD daemon is running
    [[ $(mpc | wc -l) -gt 1 ]]; then # MPD is active
    return 0

  else
    return 1
  fi
}

# Get the initial state of the player without an event.
# Do not work it the MPC tool is not installed.
#
# Returns:
#   MPD state in format as form subscriber
#
function getInitialState() {
  local state artist title

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

  artist=$(mpc --format "%artist%" | head -n1)
  title=$(mpc --format "%title%" | head -n1)

  echo "${state}:${artist}:${title}"
}

# Interface

# Implement the interface function for the initial subscription state.
#
function initState_mpd() {
  startSubscriber

  if isMpdActive; then
    format_mpd "$(getInitialState)"

  else
    STATE="${MPD_ICON_BASE}"
  fi
}

# Implement the interface function to format the current state of the subscription.
#
function format_mpd() {
  STATE="${MPD_ICON_BASE} "

  local state artist title
  state=$(awk -F ':' '{print $1}' <<<"$1")
  artist=$(awk -F ':' '{print $2}' <<<"$1")
  title=$(awk -F ':' '{print $3}' <<<"$1")

  if [[ "$state" != "stop" ]]; then
    STATE+=" $(getStateFormatString "$state")"
    STATE+=" $(abbreviate "$artist" "mpd")"
    STATE+=" - "
    STATE+="$(abbreviate "$title" "mpd")"
  fi
}
