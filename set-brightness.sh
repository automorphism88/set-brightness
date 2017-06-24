#!/bin/sh
set -e

# set this variable appropriately before running script
brightness_dir="/sys/devices/pci0000:00/0000:00:01.0/drm/card0/card0-eDP-1/amdgpu_bl0"

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

usage() {
    printf "Usage is:\n"
    printf "%s [n]   \tset brightness to n\n" "$0"
    printf "%s [n] + \tincrease brightness by n%% of current value\n" "$0"
    printf "%s [n] - \tdecrease brightness by n%% of current value\n" "$0"
    printf "%s [n] ++\tincrease brightness by n\n" "$0"
    printf "%s [n] --\tdecrease brightness by n\n" "$0"
    exit $1
}

set_brightness() {
    if [ "$1" -gt "$max_brightness" ] ; then
        new_brightness="$max_brightness"
    elif [ "$1" -lt 1 ] ; then
        new_brightness=1
    else
        new_brightness="$1"
    fi
    printf "Changing brightness from %s to %s\n" "$old_brightness" "$new_brightness"
    printf "%s\n" "$new_brightness" > "${brightness_dir}/brightness"
}

pct_brightness() {
    if [ "$2" -eq 0 ] ; then
        set_brightness "$1"
    else        
        delta="$(( ${1}*${2}/100 ))"
        if [ "$delta" -eq 0 ] ; then
            if [ "$2" -gt 0 ] ; then
                delta=1
            else
                delta=-1
            fi
        fi
        set_brightness "$(( $old_brightness+$delta ))"
    fi
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ] ; then
    usage 0
fi

if ! [ -d "$brightness_dir" ] ; then
    printf "\$brightness_dir doesn't exist - please edit variable at beginning of script\n" >&2
    exit 4
fi

old_brightness="$(cat "${brightness_dir}/brightness")"
max_brightness="$(cat "${brightness_dir}/max_brightness")"

printf "Current brightness is %s (%s%% of the maximum %s)\n" "${old_brightness}" "$(( 100*$old_brightness/$max_brightness ))" "${max_brightness}"

if ! [ -w "${brightness_dir}/brightness" ] ; then
    printf "Error: no write permission for %s\n" "${brightness_dir}/brightness" >&2
    exit 3
fi

case $1 in
    ''|*[!0-9]*) usage 2 >&2 ;;
    *)
        case $2 in
            '++') set_brightness "$(( $old_brightness+$1 ))" ;;
            '--') set_brightness "$(( $old_brightness-$1 ))" ;;
            '+') pct_brightness "$old_brightness" "$1" ;;
            '-') pct_brightness "$old_brightness" "$(( -1*$1 ))" ;;
            *) set_brightness "$1" ;;
        esac ;;
esac
