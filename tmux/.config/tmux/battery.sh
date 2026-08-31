#!/usr/bin/env bash
# Print battery percentage for the tmux status bar. Cross-platform (macOS/Linux).
# Outputs nothing if no battery is found (e.g. desktops).

if command -v pmset >/dev/null 2>&1; then
	# macOS
	pmset -g batt | grep -o '[0-9]\+%' | head -1
elif [ -d /sys/class/power_supply ]; then
	# Linux
	for bat in /sys/class/power_supply/BAT*; do
		[ -r "$bat/capacity" ] && printf '%s%%\n' "$(cat "$bat/capacity")" && break
	done
fi
