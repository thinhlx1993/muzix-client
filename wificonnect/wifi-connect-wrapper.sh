#!/bin/bash

WIFI_CONNECT_BIN="/home/thinh/music/wificonnect/wifi-connect"
WIFI_CONNECT_SSID="WiFi Connect"
WIFI_CONNECT_TIMEOUT=120
sleep 30

while true; do
    # Rescan
    nmcli dev wifi rescan >/dev/null 2>&1

    # Check current SSID via NetworkManager
    CURRENT_SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)

    if [ -n "$CURRENT_SSID" ] && [ "$CURRENT_SSID" != "$WIFI_CONNECT_SSID" ]; then
        if pgrep -x "wifi-connect" > /dev/null; then
            echo "Connected to $CURRENT_SSID. Stopping wifi-connect..."
            pkill -x "wifi-connect"
        else
            echo "Connected to $CURRENT_SSID"
        fi
    else
        echo "Not connected or only connected to WiFi Connect → try reconnect"
        nmcli device connect wlan0 >/dev/null 2>&1   # Force reconnect first

        sleep 5
        CURRENT_SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)

        if [ -z "$CURRENT_SSID" ] || [ "$CURRENT_SSID" = "$WIFI_CONNECT_SSID" ]; then
            if ! pgrep -x "wifi-connect" > /dev/null; then
                echo "Still no valid Wi-Fi. Starting WiFi Connect..."
                sudo "$WIFI_CONNECT_BIN" &
                WIFI_CONNECT_PID=$!

                (
                    sleep "$WIFI_CONNECT_TIMEOUT"
                    if kill -0 $WIFI_CONNECT_PID 2>/dev/null; then
                        echo "Timeout reached ($WIFI_CONNECT_TIMEOUT sec). Stopping wifi-connect..."
                        sudo pkill -x "wifi-connect"
                    fi
                ) &
            fi
        fi
    fi

    sleep 30
done
