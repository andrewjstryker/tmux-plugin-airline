#!/usr/bin/env bash
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
# airline-api.sh
#
# Provide an API to status line elements.
#
# This API hides the implementation details of managing themes. The biggest
# benefit is that the API records when theme elements changed. This allows API
# users to update only when needed.
#
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/scripts/shared.sh"

AIRLINE_PREFIX="@airline"
AIRLINE_REFRESH_FLAG="${AIRLINE_PREFIX}-refresh"

#-----------------------------------------------------------------------------#
#
# Internal functions
#
#-----------------------------------------------------------------------------#

_set_airline () {
  set_tmux_option "$1" "$2"
  set_tmux_option "$AIRLINE_REFRESH_FLAG" 1
}


_set_theme_element () {
  local element="$1"
  local value="$2"

  set_tmux_option "${AIRLINE_REFRESH_FLAG}" 1
  _set_airline "${AIRLINE_PREFIX}-theme-$element" "$value"
}

_get_theme_element () {
  local element="$1"
  local default="$2"

  get_tmux_option "${AIRLINE_PREFIX}-theme-$element" "$default"
}

_set_status_element () {
  local element="$1"
  local value="$2"

  set_tmux_option "${AIRLINE_REFRESH_FLAG}" 1
  _set_airline "${AIRLINE_PREFIX}-status-$element" "$value"
}

_get_status_element () {
  local element="$1"

  # clients need to test for empty strings
  tmux show-option -gqv "${AIRLINE_PREFIX}-status-$element"
}

#-----------------------------------------------------------------------------#
#
# Theme elements
#
#-----------------------------------------------------------------------------#

# primary text color (foreground)
set_theme_primary () {
  _set_theme_element primary "$1"
}

get_theme_primary () {
  _get_theme_element primary white
}

# secondary text color (foreground)
set_theme_secondary () {
  _set_theme_element secondary "$1"
}

get_theme_secondary () {
  _get_theme_element secondary white
}

# emphasized text color (foreground)
set_theme_emphasized () {
  _set_theme_element emphasized "$1"
}

get_theme_emphasized () {
  _get_theme_element emphasized brightwhite
}

# outer background
set_theme_outer () {
  _set_theme_element outer "$1"
}

get_theme_outer () {
  _get_theme_element outer brightgreen
}

# middle background
set_theme_middle () {
  _set_theme_element middle "$1"
}

get_theme_middle () {
  _get_theme_element middle green
}

# inner background
set_theme_inner () {
  _set_theme_element inner "$1"
}

get_theme_inner () {
  _get_theme_element inner black
}

# current/active elements (highlight)
set_theme_current () {
  _set_theme_element current "$1"
}

get_theme_current () {
  _get_theme_element current brightyellow
}

# alert to get user's attention
set_theme_alert () {
  _set_theme_element alert "$1"
}

get_theme_alert () {
  _get_theme_element alert yellow
}

# stress, draw attention to high loads/resources nearing limits
set_theme_stress () {
  _set_theme_element stress "$1"
}

get_theme_stress () {
  _get_theme_element stress red
}

# copy mode
set_theme_copy () {
  _set_theme_element copy "$1"
}

get_theme_copy () {
  _get_theme_element copy blue
}

# window zoomed
set_theme_zoom () {
  _set_theme_element zoom "$1"
}

get_theme_zoom () {
  _get_theme_element zoom blue
}

# window monitoring
set_theme_monitor () {
  _set_theme_element monitor "$1"
}

get_theme_monitor () {
  _get_theme_element monitor blue
}

# "special" state (e.g., prefix key active)
set_theme_special () {
  _set_theme_element special "$1"
}

get_theme_special () {
  _get_theme_element special magenta
}

#-----------------------------------------------------------------------------#
#
# Status line components
#
#-----------------------------------------------------------------------------#

set_status_left_outer () {
  _set_status_element "left-outer" "$1"
}

get_status_left_outer () {
  local status

  status=$(_get_status_element "left-outer")

  if [[ -z $status ]]
  then
    if [[ $(is_online_installed) ]]
    then
      status="$status #(online_status)"
    fi
    set_status_left_outer "$status #S"
  fi

  echo "$status"
}

set_status_left_middle () {
  _set_status_element "left-middle" "$1"
}

get_status_left_middle () {
  local status

  status=$(_get_status_element "left-middle")

  if [[ -z $status ]]
  then
    status="$(_get_status_element "left-inner") > #S"
    set_status_left_middle "$status"
  fi

  echo "$status"
}

set_status_left_inner () {
  _set_status_element "left-inner" "$1"
}

get_status_left_inner () {
  local status

  _get_status_element "left-inner"

  if [[ -z $status ]]
  then
    status=" "
    set_status_left_inner "$status"
  fi

  echo "$status"
}

set_status_right_inner () {
  _set_status_element "right-inner" "$1"
}

get_status_right_inner () {
  local status

  _get_status_element "right-inner"

  if [[ -z $status ]]
  then
    if [[ $(is_prefix_installed) ]]
    then
      status="#(prefix_highlight)"
    fi
  fi

  echo "$status"
}

set_status_right_middle () {
  _set_status_element "right-middle" "$1"
}

get_status_right_middle () {
  local status

  _get_status_element "right-middle"

  if [[ -z $status ]]
  then
    status=" "
    set_status_right_middle "$status"
  fi

  echo "$status"
}

set_status_right_outer () {
  _set_status_element "right-outer" "$1"
}

get_status_right_outer () {
  local status

  _get_status_element "right-outer"

  if [[ -z $status ]]
  then
    if [[ $(is_battery_installed) ]]
    then
      status="#{battery_color_fg}#{battery_icon}"

      tmux set -g @batt_color_full_charge "#[fg=$(get_theme_primary)]"
      tmux set -g @batt_color_high_charge "#[fg=$(get_theme_emphasized)]"
      tmux set -g @batt_color_medium_charge "#[fg=$(get_theme_alert)]"
      tmux set -g @batt_color_low_charge "#[fg=$(get_theme_stress)]"

      tmux set -g @batt_color_charge_primary_tier8 "$(get_theme_primary)"
      tmux set -g @batt_color_charge_primary_tier7 "$(get_theme_primary)"
      tmux set -g @batt_color_charge_primary_tier6 "$(get_theme_emphasized)"
      tmux set -g @batt_color_charge_primary_tier5 "$(get_theme_emphasized)"
      tmux set -g @batt_color_charge_primary_tier4 "$(get_theme_alert)"
      tmux set -g @batt_color_charge_primary_tier3 "$(get_theme_alert)"
      tmux set -g @batt_color_charge_primary_tier2 "$(get_theme_stress)"
      tmux set -g @batt_color_charge_primary_tier1 "$(get_theme_stress)"

      # icons to show when discharging the battery
      tmux set -g @batt_icon_charge_tier8 '🌑'
      tmux set -g @batt_icon_charge_tier7 '🌘'
      tmux set -g @batt_icon_charge_tier6 '🌘'
      tmux set -g @batt_icon_charge_tier5 '🌗'
      tmux set -g @batt_icon_charge_tier4 '🌗'
      tmux set -g @batt_icon_charge_tier3 '🌖'
      tmux set -g @batt_icon_charge_tier2 '🌖'
      tmux set -g @batt_icon_charge_tier1 '🌕'

      # icons to show when charging the battery
      tmux set -g @batt_icon_status_charged '🔋'
      tmux set -g @batt_icon_status_charging '⚡'
      tmux set -g @batt_color_status_primary_charged "$(get_theme_primary)"
      tmux set -g @batt_color_status_primary_charging "$(get_theme_current)"
      tmux set -g @batt_color_status_primary_unknown "$(get_theme_stress)"
    fi
    status="%b %d %H:%M $status"
    set_status_right_outer "$status"
  fi

  echo "$status"
}

#-----------------------------------------------------------------------------#
#
# User functions
#
#-----------------------------------------------------------------------------#

airline_refresh_needed () {
  # note numerical testing
  if (( "$(get_tmux_option "${AIRLINE_REFRESH_FLAG}" "1" )" ))
  then
    return 1
  fi

  return 0
}

airline_refresh_clear () {
  set_tmux_option "${AIRLINE_REFRESH_FLAG}" 0
}

airline_load_theme () {
  local theme="$1"

  # theme a readable file?
  if [[ -r "$theme" && -f "$theme" ]]
  then
    source "$theme"
    return
  fi

  # theme part of airline's default themes?
  local target="$CURRENT_DIR/themes/$theme"
  if [[ -r "$target" && -f "$target" ]]
  then
    source "$target"
    return
  fi

  # could not load theme
  return 1
}

# vim: sts=2 sw=2 et
