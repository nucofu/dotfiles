#!/bin/bash

# required dependencies
# echo, awk, date, cat, sensors, brightnessctl, amixer, wmctrl, ls, iw, sleep, lemonbar

primary_bright_color="#19bcff"
primary_normal_color="#19abff"
primary_low_color="#199aff"

background_color="#991e1e2e"
border_color="#282828"

red_color="#de1009"
green_color="#10de09"
yellow_color="#ffe74f"

waktu() {
    kalender="$(date +"%A, %d %B")"
    jam="$(date +"%R")"

    out_a="%{F$primary_bright_color}$jam%{F-} $kalender"
}

baterai() {
    baterai="$(cat /sys/class/power_supply/BAT1/capacity)"
    status="$(cat /sys/class/power_supply/BAT1/status)"
    title=""

    if [[ "$status" == "Charging" ]]; then
        title="%{F$green_color}Bat%{F-}"
    elif [[ "$status" == "Full" ]]; then
        title="%{F$green_color}Bat%{F-}"
    else
       if [ $baterai -lt 20 ]; then
           title="%{F$red_color}Bat%{F-}"
       else
          title="%{F$primary_bright_color}Bat%{F-}"
       fi
    fi

    out_b="$title $baterai%"

}

ram() {
    ram="$(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{print int((t-a)*100/t)}' /proc/meminfo)"

    if [ $ram -gt 80 ]; then
        out_c="%{F$red_color}RAM%{F-} $ram%"
    else
        out_c="%{F$primary_bright_color}RAM%{F-} $ram%"
    fi
}

temp() {
    temp="$(sensors coretemp-isa-0000 | awk -F"[+|°]" '/Core 0:/ { print $2 }')"
    temp_int=${temp%.*}

    if [ $temp_int -gt 55 ]; then
        out_d="%{F$red_color}Temp%{F-} $temp_int°C"
    else
        out_d="%{F$primary_bright_color}Temp%{F-} $temp_int°C"
    fi
    
}

backlight() {
    backlight="$(brightnessctl | awk -F"[(|%]" '/Current brightness: / {print $2}')"
    
    out_e="%{A4:brightnessctl -q set +5%:}%{A5:brightnessctl -q set 5%-:}%{F$primary_bright_color}Bright%{F-} $backlight%%%{A4}%{A5}"
}

volume() {
    amout="$(amixer -M get Master)"
    volume="$(echo "$amout" | awk -F"[][%]" '/Left:/ { print $2 }')"
    status="$(echo "$amout" | awk -F"[][]" '/Left:/ { print $4 }')"

    [ "$status" == "off" ] && out_f="%{F$primary_bright_color}Vol%{F-} %{F$red_color}MUTED%{F-}" && return
    
    out_f="%{A4:amixer -q sset Master 5%+:}%{A5:amixer -q sset Master 5%-:}%{F$primary_bright_color}Vol%{F-} $volume%%%{A4}%{A5}"
}

workspace() {
    unset out_g
    list_w="$(wmctrl -d)"
    for i in 0 1 2 3; do
        dat="$(echo "$list_w" | awk -v idx="$i" '$1 == idx {print $2}')"
        if [ "$dat" == "*" ]; then
            out_g+=" %{F$primary_bright_color}$i%{F-} "
        else
            out_g+=" %{A:wmctrl -s $i:}$i%{A} "
        fi
    done
}

cpu() {
    total="$(awk '/cpu / {print int($1+$2+$3+$4+$5+$6+$7+$8+$9+$10+$11)}' /proc/stat)"
    idle="$(awk '/cpu / {print int($5+$6)}' /proc/stat)"

    diff_total=$((total - prev_total))
    diff_idle=$((idle - prev_idle))

    cpu_usage=$((((diff_total - diff_idle) * 100) / diff_total))

    if [ $cpu_usage -gt 80 ]; then
        out_h="%{F$red_color}CPU%{F-} $cpu_usage%"
    else
        out_h="%{F$primary_bright_color}CPU%{F-} $cpu_usage%"
    fi
    
    prev_total=$total
    prev_idle=$idle
}

wifi() {
    # ambil interface wireless pertama
    iface="$(ls /sys/class/net 2>/dev/null | grep '^wl' | head -n1)"
    [ -z "$iface" ] && out_i="%{A:cmst > /dev/null 2>&1 &:}%{F$primary_bright_color}$iface%{F-} down%{A}" && return

    # wifi state
    state="$(cat /sys/class/net/$iface/operstate 2>/dev/null)"

    # connected SSID
    connSSID="$(iw dev $iface link | awk '/SSID/{name=$2}END{if (name != "") {print " ["name"] "} else {print " "}}')"
    
    if [ "$state" != "up" ]; then
        out_i="%{A:cmst > /dev/null 2>&1 &:}%{F$primary_bright_color}$iface%{F-} down%{A}"
        return
    else
        if [ "$connSSID" != " " ]; then                
            # strength (%)
            strength="$(iw dev $iface link | awk '/signal/{dbm=$2}END{if (dbm != "") {print int(((dbm+100)*100)/60)}}')"
            [ -z "$strength" ] && strength=0
            
            #limit strength
            if [ $strength -gt 100 ]; then
                strength=+100
            elif [ $strength -lt 0 ]; then
                strength=-0
            fi
            
            # Strength Color Indicator
            if [ $strength -gt 70 ]; then
                ipi="%{A:cmst > /dev/null 2>&1 &:}%{F$green_color}$iface$connSSID%{F-}${strength}%%%{A}"
            elif [ $strength -lt 30 ]; then
                ipi="%{A:cmst > /dev/null 2>&1 &:}%{F$red_color}$iface$connSSID%{F-}${strength}%%%{A}"
            else
                ipi="%{A:cmst > /dev/null 2>&1 &:}%{F$primary_bright_color}$iface$connSSID%{F-}${strength}%%%{A}"
            fi
            out_i="$ipi"

        else
            out_i="%{A:cmst > /dev/null 2>&1 &:}%{F$primary_bright_color}$iface%{F-} up%{A}"
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

    rx=0
    tx=0

    # auto convert K/M
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

    out_j="%{F$primary_bright_color}d/u%{F-} ${rx_out}/${tx_out}"

}

# CPU previous stat
prev_total="$(awk '/cpu / {print int($1+$2+$3+$4+$5+$6+$7+$8+$9+$10+$11)}' /proc/stat)"
prev_idle="$(awk '/cpu / {print int($5+$6)}' /proc/stat)"

# interface, upload and download previous stat
iface="$(ls /sys/class/net 2>/dev/null | grep '^wl' | head -n1)"
prev_rx="$(cat /sys/class/net/$iface/statistics/rx_bytes 2>/dev/null)"
prev_tx="$(cat /sys/class/net/$iface/statistics/tx_bytes 2>/dev/null)"

separator="%{F$yellow_color}|%{F-}"

while true; do
    workspace
    wifi
    ram
    cpu
    baterai
    temp
    volume
    backlight
    waktu
    traffic_bytes
    
    echo "$out_g %{r}$out_i $separator $out_j $separator $out_c $separator $out_h $separator $out_b $separator $out_d $separator $out_f $separator $out_e $separator $out_a "
    sleep 1
done | lemonbar -b -B "$background_color" -p | bash
