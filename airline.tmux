#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/scripts/shared.sh"
source "$CURRENT_DIR/scripts/is_installed.sh"

#-----------------------------------------------------------------------------#
#
# Load color scheme
#
#-----------------------------------------------------------------------------#

load_color_scheme () {
	local color_scheme=$(get_tmux_option airline_color_scheme solarized)

	source "$CURRENT_DIR/themes/$color_scheme"
	declare -p theme
}

#-----------------------------------------------------------------------------#
#
# Chevrons
#
#-----------------------------------------------------------------------------#

chevron () {
	local left_bg="$1"
	local right_bg="$2"
	local chev="$3"

	echo "#[fg=$right_bg,bg=$left_bg]$chev"
}

chev_right () {
	local left_bg="$1"
	local right_bg="$2"
	chevron "$right_bg" "$left_bg" ""
}

chev_left () {
	local left_bg="$1"
	local right_bg="$2"
	chevron "$left_bg" "$right_bg" ""
}

#-----------------------------------------------------------------------------#
#
# Create widget template
#
# Build a template from installed popular widgets, if the user did not define
# a left middle template.
#
#-----------------------------------------------------------------------------#

create_widget_template () {
	local template=""

	if [[ is_cpu_installed ]]
	then
		template="$template #{cpu_fg_color}#{cpu_icon}#[bg=${theme[middle_bg]}"
		template="$template #{gpu_fg_color}#{gpu_icon}#[bg=${theme[middle_bg]}"
		set -g @cpu_low_fg_color "$primary_fg" # foreground color when cpu is low
		set -g @cpu_medium_fg_color "$emphasized_fg" # foreground color when cpu is medium
		set -g @cpu_high_fg_color "$stress" # foreground color when cpu is high

		set -g @cpu_low_bg_color "$middle_bg" # background color when cpu is low
		set -g @cpu_medium_bg_color "$middle_bg" # background color when cpu is medium
		set -g @cpu_high_bg_color "$middle_bg" # background color when cpu is high

	fi

	if [[ online_installed ]]
	then
		template=" #{online_status}"
		set -g @online_icon "#[fg=$color_level_ok]●#[default]"
		set -g @offline_icon "#[fg=$color_level_stress]●#[default]"
	fi

	if [[ is_online_installed ]]
	then
		template="$template #{online_status}"
		set -g @online_icon "#[fg=$color_level_ok]●#[default]"
		set -g @offline_icon "#[fg=$color_level_stress]●#[default]"
	fi

	if [[ is_battery_installed ]]
	then
		set -g @batt_color_full_charge "#[fg=$color_level_ok]"
		set -g @batt_color_high_charge "#[fg=$color_level_ok]"
		set -g @batt_color_medium_charge "#[fg=$color_level_warn]"
		set -g @batt_color_low_charge "#[fg=$color_level_stress]"
		template="$template #{battery_status}"
	fi

	echo $template
}

set_right_inner_template () {
	if [[ is_prefix_installed ]]
	then
		tmux set -g @prefix_highlight_output_prefix '['
		tmux set -g @prefix_highlight_output_suffix ']'
		tmux set -g @prefix_highlight_fg "${theme[emphasized_fg]}"
		tmux set -g @prefix_highlight_bg "${theme[special]}"
		tmux set -g @prefix_highlight_show_copy_mode 'on'
		tmux set -g @prefix_highlight_copy_mode_attr "fg=${them[emphasized_fg]},bg=${theme[copy]}"
	fi

	echo " #{prefix_highlight} "
}

#-----------------------------------------------------------------------------#
#
# Build status line components
#
#-----------------------------------------------------------------------------#

left_outer () {
	local template="$(get_tmux_option airline_tmpl_left_out '#H')"
	local fg="${theme[emphasized_fg]}"
	local bg="${theme[outer_bg]}"
	local next_bg="${theme[middle_bg]}"

	echo "#[fg=$fg,bg=$bg]${template}$(chev_right $bg $next_bg)"
}

left_middle () {
	local template="$(get_tmux_option airline_tmpl_left_middle '#S')"
	local fg="${theme[emphasized_fg]}"
	local bg="${theme[middle_bg]}"
	local next_bg="${theme[inner_bg]}"

	echo "#[fg=$fg,bg=$bg]${template}$(chev_right $bg $next_bg) "
}

window_status () {
	local template="$(get_tmux_option airline_tmpl_window '#I:#W')"

	echo "$template"
}

window_current () {
	local template="$(get_tmux_option airline_tmpl_window_current '#I:#W')"
	local bg="${theme[inner_bg]}"
	local hi="${theme[highlight]}"

	echo "$(chev_right $bg $hi) $template $(chev_left $hi $bg)"
}

right_inner () {
	# explicitly check as we call a function to build the template
	local fg="${theme[primary_fg]}"
	local bg="${theme[inner_bg]}"
	local template

	template="$(tmux show-option -gqv airline_tmpl_right_inner)"
	if [[ -z "$template" ]]
	then
		template="$(set_right_inner_template)"
	fi

	echo "#[fg=$fg,bg=$bg]${template}"
}

right_middle () {
	# explicitly check as we call a function to build the template
	local template="$(get_tmux_option airline_tmpl_right_middle '  ')"
	local fg="${theme[emphasized_fg]}"
	local bg="${theme[middle_bg]}"
	local prev_bg="${theme[inner_bg]}"

	echo "$(chev_left $prev_bg $bg)#[fg=$fg,bg=$bg]${template}"
}

right_outer () {
	local template="$(get_tmux_option airline_tmpl_right_outer '%Y-%m-%d %H:%M')"
	local fg="${theme[emphasized_fg]}"
	local bg="${theme[outer_bg]}"
	local prev_bg="${theme[middle_bg]}"

	echo "$(chev_left $prev_bg $bg)#[fg=$fg,bg=$bg]${template}"
}

#-----------------------------------------------------------------------------#
#
# Set status elements
#
#-----------------------------------------------------------------------------#

main () {
	eval "$(load_color_scheme)"

	# TODO: is this needed?
	# TODO: what is mode-style?
	#tmux set -gq mode-style "fg=${theme[special]} bg=${theme[alert]}"
	# tmux set -gq message-command-style
	#tmux set -gq window-last-style "fg=${theme[primary_fg]} bg=${theme[middle_bg]}"
	#tmux set -gq window-current-style "fg=${theme[primary_fg]} bg=${theme[highlight]}"
	# tmux set -gq window-style "fg=${theme[primary_fg]} bg=${theme[inner_bg]}"
	#tmux set -gq window-active-style "fg=${theme[window_fg]} bg=${theme[alert]}"

	# Configure panes, use highlight color for active panes
	tmux set -gq pane-border-style "fg=${theme[primary_fg]}"
	tmux set -gq pane-active-border-style "fg=${theme[highlight]}"
	tmux set -gq display-panes-color "${theme[primary_fg]}"
	tmux set -gq display-panes-active-color "${theme[highlight]}"

	# Build the status bar
	tmux set -gq status-style "fg=${theme[secondary_fg]} bg=${theme[inner_bg]}"

	# Configure window status
	tmux set -gq window-status-separator-string " "
	tmux set -gq window-status-format "$(window_status)"
	tmux set -gq window-status-style "fg=${theme[primary_fg]} bg=${theme[inner_bg]}"
	tmux set -gq window-status-last-style "fg=${theme[emphasized_fg]} bg=${theme[inner_bg]}"
	tmux set -gq window-status-current-format "$(window_current)"
	tmux set -gq window-status-activity-style "fg=${theme[alert]} bg=${theme[inner_bg]}"
	tmux set -gq window-status-bell-style "fg=${theme[stress]} bg=${theme[inner_bg]}"

	tmux set -gq status-left-style "fg=${theme[primary_fg]} bg=${theme[outer_bg]}"
	tmux set -gq status-left "$(left_outer) $(left_middle)"

	tmux set -gq status-right-style "fg=${theme[primary_fg]} bg=${theme[outer_bg]}"
	tmux set -gq status-right "$(right_inner) $(right_middle) $(right_outer)"

	tmux set -gq clock-mode-color "${theme[special]}"

}

main
