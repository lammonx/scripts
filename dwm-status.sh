#!/bin/bash
#author:lammon

function disk() {
	icon=""
	location=${1:-/}
	printf "%s%s\n" "$icon" "$(df -h "$location" | awk ' /[0-9]/ {print $3}')"
}

function memory() {
	free --mebi | sed -n '2{p;q}' | awk '{printf ("%2.2fG\n", ( $3 / 1024))}'
}

function backlight() {
	backlight="$(cat /sys/class/backlight/amdgpu_bl0/actual_brightness)"
	echo "$backlight"
}

function battery() {
	# Loop through all attached batteries and format the info
	for battery in /sys/class/power_supply/BAT?*; do
		# If non-first battery, print a space separator.
		[ -n "${capacity+x}" ] && printf " "
		# Sets up the status and capacity
		case "$(cat "$battery/status" 2>&1)" in
			"Full") status="F:" ;;
			"Discharging") status="DC:" ;;
			"Charging") status="C:" ;;
			"Not charging") status="NC:" ;;
			"Unknown") status="UN:" ;;
			*) exit 1 ;;
		esac
		capacity="$(cat "$battery/capacity" 2>&1)"
		# Will make a warn variable if discharging and low
		[ "$status" = "" ] && [ "$capacity" -le 25 ] && warn=""
		# Prints the info
		printf "%s%s%d%%" "$status" "$warn" "$capacity"; unset warn
	done && printf "\\n"
}

function clock() {
	date "+%Y-%m-%d(%A)%I:%M:%S%p"
}

function internet() {
	if grep -xq 'up' /sys/class/net/w*/operstate 2>/dev/null ; then
		wifiicon="$(awk '/^\s*w/ { print "📶", int($3 * 100 / 70) "% " }' /proc/net/wireless)"
	elif grep -xq 'down' /sys/class/net/w*/operstate 2>/dev/null ; then
		grep -xq '0x1003' /sys/class/net/w*/flags && wifiicon="📡 " || wifiicon="❌ "
	fi
	printf "%s%s%s\n" "$wifiicon" "$(sed "s/down/❎/;s/up/🌐/" /sys/class/net/e*/operstate 2>/dev/null)" "$(sed "s/.*/🔒/" /sys/class/net/tun*/operstate 2>/dev/null)"
}

function volume() {
	[ $(pamixer --get-mute) = true ] && echo "0%" && exit
	vol="$(pamixer --get-volume)"
	echo "$vol%"
}

function main() {
	while true; do
		xsetroot -name "M:$(memory)|S:$(disk)|B:$(backlight)|V:$(volume)|$(clock)|$(battery)|$(internet)"
		sleep 1
	done
}
# echo "$(memory)"
main
