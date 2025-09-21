#!/bin/bash

export WAYLAND_DISPLAY="wayland-1"
export SWAYSOCK=$(ls /run/user/1000/sway-ipc.1000.*.sock)


if [[ "$1" == "on" ]]; then
#    swaymsg output DP-1 mode 3440x1440@240.085Hz max_render_time 4
    swaymsg output DP-1 adaptive_sync on
#    swaymsg output DP-1 render_bit_depth 10
    sudo /home/yama/scripts/perf_mode.sh high
    scxctl switch --sched lavd --mode performance
    ddcutil getvcp -t 10 -n 412NTNH8B575 | cut -d' ' -f4 > /tmp/monitor_brightness.txt
    #ddcutil setvcp 12 100 -n 412NTNH8B575
    ddcutil setvcp 10 90 -n 412NTNH8B575
    sleep 5
    swaymsg max_render_time 4
    xrandr --output DP-1 --pos 0x0
    dunstctl set-paused true
#    gpu-screen-recorder -w portal -restore-portal-session yes -f 60 -q medium -r 20 -k av1 -c webm -ac opus -a "$(pactl get-default-sink).monitor" -o /tmp -v no -sc /home/yama/scripts/clip_upload.sh  > /tmp/gamemode.log 2>&1 &
    gpu-screen-recorder -w DP-1 -f 60 -q medium -r 20 -k av1 -bm vbr -c webm -ac opus -a "$(pactl get-default-sink).monitor" -o /tmp -v no -sc /home/yama/scripts/clip_upload.sh  > /tmp/gamemode.log 2>&1 &
#    pgrep log_mem.sh
#    pec=$?
    #if [[ pec != 0 ]]; then
    #    /home/yama/scripts/log_mem.sh &
    #fi
else
#    pkill -f gpu-screen-recorder
    killall -SIGINT gpu-screen-recorder
    dunstctl set-paused false
#    swaymsg output DP-1 mode 3440x1440@60.003Hz
    swaymsg output DP-1 adaptive_sync off
#    swaymsg output DP-1 max_render_time off
#    swaymsg output DP-1 render_bit_depth 10
    #ddcutil setvcp 12 30 -n 412NTNH8B575
    old_brightness=$(cat /tmp/monitor_brightness.txt)
    ddcutil setvcp 10 $old_brightness -n 412NTNH8B575
    sudo /home/yama/scripts/perf_mode.sh low
    scxctl switch --sched lavd --mode powersave
fi
