#!/bin/bash

INTERVAL=2

BAT="/sys/class/power_supply/BAT1"
ADP="/sys/class/power_supply/ADP1"
[ -d "$BAT" ] || BAT="$(find /sys/class/power_supply -maxdepth 1 -iname 'BAT*' 2>/dev/null | head -n1)"
[ -d "$ADP" ] || ADP="$(find /sys/class/power_supply -maxdepth 1 \( -iname 'ADP*' -o -iname 'AC*' \) 2>/dev/null | head -n1)"

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/battery-monitor"
mkdir -p "$STATE_DIR"

set_flag()   { : > "$STATE_DIR/$1"; }
clear_flag() { rm -f "$STATE_DIR/$1"; }
has_flag()   { [ -e "$STATE_DIR/$1" ]; }

if [ -z "$BAT" ]; then
    notify-send -u critical "Battery Monitor" "Device baterai tidak ditemukan"
    exit 1
fi

while :; do
    capacity="$(cat "$BAT/capacity" 2>/dev/null)"
    status="$(cat "$BAT/status" 2>/dev/null)"
    adapter_online="$(cat "$ADP/online" 2>/dev/null)"

    if [ -z "$capacity" ] || [ -z "$status" ]; then
        sleep "$INTERVAL"; continue
    fi
    
    if [ "$adapter_online" = "1" ]; then

        if has_flag adp_offline; then
            clear_flag adp_offline
        fi

        if ! has_flag adp_online; then
            notify-send -u normal -i battery-empty-charging "Adapter Terhubung"
            set_flag adp_online
        fi
        
        # baterai up to 80%.
        if [ "$status" == "Charging" ] && [ "$capacity" -ge 80 ]; then
            if ! has_flag unplug; then
                notify-send -u normal -i battery-080-charging "Baterai 80%" "Segera lepaskan charger adapter"
                set_flag unplug
            fi
        else
            clear_flag unplug
        fi
        
        # baterai full 100%
        if [ "$status" == "Full" ] && [ "$capacity" -ge 100 ]; then
            if ! has_flag full; then
                notify-send -u normal -i battery-full-charging "Baterai Penuh" "Segera lepaskan charger adapter"
                set_flag full
            fi
        else
            clear_flag full
        fi

        # ganti baterai ke adapter
        if [ "$status" == "Not charging" ]; then
            if ! has_flag adp_bypass; then
                notify-send -u normal -i preferences-system-power "Power Supply berganti ke Adapter" "sekarang laptop anda mengambil daya dari adapter"
                set_flag adp_bypass
            fi
        else
            clear_flag adp_bypass
        fi

        
    elif [ "$adapter_online" = "0" ]; then

        if has_flag adp_online; then
            clear_flag adp_online
        fi

        if ! has_flag adp_offline; then
            notify-send -u normal -i battery-missing "Adapter Terputus"
            set_flag adp_offline
        fi
        
        if [ "$status" == "Discharging" ]; then

            # baterai critical (<=5%)
            if [ "$capacity" -le 5 ]; then
                if ! has_flag critical; then
                    notify-send -u critical -i battery-caution "Baterai Kritis" "Sisa ${capacity}%, segera sambungkan ke adapter"
                    set_flag critical
                fi
            else
                clear_flag critical
            fi
            
            # baterai menipis (<=15%, di atas critical)
            if [ "$capacity" -le 15 ] && [ "$capacity" -gt 5 ]; then
                if ! has_flag low; then
                    notify-send -u normal -i battery-low "Baterai Menipis" "Sisa ${capacity}%"
                    set_flag low
                fi
            else
                clear_flag low
            fi    
        fi
    fi
    
    sleep "$INTERVAL"
done
