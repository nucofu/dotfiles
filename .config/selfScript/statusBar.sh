#!/bin/bash

# required dependencies
# echo, awk, date, cat, sensors, brightnessctl, amixer, wmctrl, ls, iw, sleep, lemonbar

primary="#19bcff"
background_color="#99000000"
border_color="#282828"

red_color="#de1009"
green_color="#10de09"
yellow_color="#ffe74f"

dateNclock() {
    current_date="$(date +"%A, %d %B")"
    current_clock="$(date +"%R")"

    # output variable
    out_a="%{F$primary}$current_clock%{F-} $current_date"
}

battery() {
    bat="$(cat /sys/class/power_supply/BAT1/capacity)"
    status="$(cat /sys/class/power_supply/BAT1/status)"
    bat_line=""

    # Battery Threshold Color Indicator
    if [[ "$status" == "Charging" ]]; then
        bat_line="%{F$green_color}Bat%{F-}"
    elif [[ "$status" == "Full" ]]; then
        bat_line="%{F$green_color}Bat%{F-}"
    else
       if [ $bat -lt 20 ]; then
           bat_line="%{F$red_color}Bat%{F-}"
       else
          bat_line="%{F$primary}Bat%{F-}"
       fi
    fi

    # output variable
    out_b="$bat_line $bat%"

}

ram() {
    ram="$(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{print int((t-a)*100/t)}' /proc/meminfo)"

    # Ram Threshold Color Indicator & output variable
    if [ $ram -gt 80 ]; then
        out_c="%{F$red_color}RAM%{F-} $ram%"
    else
        out_c="%{F$primary}RAM%{F-} $ram%"
    fi
}

temp() {
    temp="$(sensors coretemp-isa-0000 | awk '/Core/ {gsub(/[+°C]/, "", $3); sum += $3; count++} END {if (count > 0) print int((sum/count) + 0.5) "°C"; else print "N/A"}')"

    # Temp Threshold Color Indicator & output variable
    if [ $temp -gt 55 ]; then
        out_d="%{F$red_color}Temp%{F-} $temp"
    else
        out_d="%{F$primary}Temp%{F-} $temp"
    fi
    
}

backlight() {
    backlight="$(brightnessctl | awk -F"[(|%]" '/Current brightness: / {print $2}')"

    # output variable
    out_e="%{A4:brightnessctl -q set +5%:}%{A5:brightnessctl -q set 5%-:}%{F$primary}Bright%{F-} $backlight%%%{A4}%{A5}"
}

volume() {
    volume="$(amixer -M get Master | awk -F"[][]" '/Playback/ && /%/ {sum += $2; count++} END {if (count > 0) print int(sum/count) "%"; else print "0%"}')"
    status="$(amixer -M get Master | awk -F"[][]" '/Playback/ && /%/ {if ($6 == "off" || $4 == "off") muted=1} END {if (muted) print "off"; else print "on"}')"

    # show MUTED if status is off
    [ "$status" == "off" ] && out_f="%{F$primary}Vol%{F-} %{F$red_color}MUTED%{F-}" && return

    # output variable
    out_f="%{A4:amixer -q sset Master 5%+:}%{A5:amixer -q sset Master 5%-:}%{F$primary}Vol%{F-} $volume%%{A4}%{A5}"
}

workspace() {
    unset out_g

    # coloring active desktop & output variable
    for i in 0 1 2 3; do
        check_desktop="$(wmctrl -d | awk -v idx="$i" '$1 == idx {print $2}')"
        if [ "$check_desktop" == "*" ]; then
            out_g+=" %{F$primary}$i%{F-} "
        else
            out_g+=" %{A:wmctrl -s $i:}$i%{A} "
        fi
    done
}

cpu() {
    total="$(awk '/cpu / {print int($2+$3+$4+$5+$6+$7+$8+$9+$10+$11)}' /proc/stat)"
    idle="$(awk '/cpu / {print int($5+$6)}' /proc/stat)"

    diff_total=$((total - prev_total))
    diff_idle=$((idle - prev_idle))

    cpu_usage=$((((diff_total - diff_idle) * 100) / diff_total))

    # CPU Threshold Color Indicator & output variable
    if [ $cpu_usage -gt 80 ]; then
        out_h="%{F$red_color}CPU%{F-} $cpu_usage%"
    else
        out_h="%{F$primary}CPU%{F-} $cpu_usage%"
    fi

    # update previous variable
    prev_total=$total
    prev_idle=$idle
}

wifi() {
    # check wireless interface
    [ -z "$iface" ] && out_i="%{A:cmst > /dev/null 2>&1 &:}%{F$primary}$iface%{F-} down%{A}" && return

    # wifi state
    state="$(cat /sys/class/net/$iface/operstate 2>/dev/null)"

    # connected SSID
    connSSID="$(iw dev $iface link | awk '/SSID: / {sub(/.*SSID: /, ""); print}')"

    # condition for output variable
    if [ "$state" != "up" ]; then
        # if device is down
        out_i="%{A:cmst > /dev/null 2>&1 &:}%{F$primary}$iface%{F-} down%{A}"
        return
    else
        if [ "$connSSID" != " " ]; then                
            # strength with dbm
            strength="$(iw dev $iface link | awk '/signal/{dbm=$2}END{if (dbm != "") {print int(dbm)}}')"
            [ -z "$strength" ] && strength=0
                        
            # Strength Color Indicator
            if [ $strength -gt -40 ]; then
                out_i="%{A:cmst > /dev/null 2>&1 &:}%{F$primary}$iface [%{F-}%{F$green_color$connSSID%{F-}%{F$primary}]%{F-} ${strength} dbm%{A}"
            elif [ $strength -lt -80 ]; then
                out_i="%{A:cmst > /dev/null 2>&1 &:}%{F$primary}$iface [%{F-}%{F$red_color}$connSSID%{F-}%{F$primary}]%{F-} ${strength} dbm%{A}"
            else
                out_i="%{A:cmst > /dev/null 2>&1 &:}%{F$primary}$iface [%{F-}$connSSID%{F-}%{F$primary}]%{F-} ${strength} dbm%{A}"
            fi

        else
            # if device is up
            out_i="%{A:cmst > /dev/null 2>&1 &:}%{F$primary}$iface%{F-} up%{A}"
            return
        fi
    fi
}

traffic_bytes() {

    # traffic bytes
    rx="$(cat /sys/class/net/$iface/statistics/rx_bytes)"
    tx="$(cat /sys/class/net/$iface/statistics/tx_bytes)"

    rx_diff=$(( (rx - prev_rx) / 1024 ))
    tx_diff=$(( (tx - prev_tx) / 1024 ))

    [ "$rx_diff" -lt 0 ] && rx_rate=0
    [ "$tx_diff" -lt 0 ] && tx_rate=0
    
    prev_rx=$rx
    prev_tx=$tx

    # auto convert Kb to Mb
    if [ "$rx_diff" -gt 1024 ]; then
        rx_out="$((rx_diff/1024))Mb"
    else
        rx_out="${rx_diff}Kb"
    fi

    if [ "$tx_diff" -gt 1024 ]; then
        tx_out="$((tx_diff/1024))Mb"
    else
        tx_out="${tx_diff}Kb"
    fi

    # output variable
    out_j="%{F$primary}d/u%{F-} ${rx_out}/${tx_out}"

}

# CPU previous stat
prev_total="$(awk '/cpu / {print int($2+$3+$4+$5+$6+$7+$8+$9+$10+$11)}' /proc/stat)"
prev_idle="$(awk '/cpu / {print int($5+$6)}' /proc/stat)"

# wireless interface
iface="$1"
if [ ! -e "/sys/class/net/$iface" ]; then
    echo "Error: interface '$iface' tidak ditemukan" >&2
    exit 1
fi

# upload and download previous stat
prev_rx="$(cat /sys/class/net/$iface/statistics/rx_bytes 2>/dev/null)"
prev_tx="$(cat /sys/class/net/$iface/statistics/tx_bytes 2>/dev/null)"

# separator
separator="%{F$yellow_color}|%{F-}"

# main loop
while true; do
    workspace
    wifi
    ram
    cpu
    battery
    temp
    volume
    backlight
    dateNclock
    traffic_bytes
    
    echo "$out_g %{r}$out_i $separator $out_j $separator $out_c $separator $out_h $separator $out_b $separator $out_d $separator $out_f $separator $out_e $separator $out_a "
    sleep 1
done | lemonbar -b -B "$background_color" -p | bash
