#!/bin/bash

WIFI_CONNECT_BIN="/home/thinh/music/wificonnect/wifi-connect"
WIFI_CONNECT_SSID="WiFi Connect"
WIFI_CONNECT_TIMEOUT=120
MAX_ERROR_COUNT=3
ERROR_COUNT=0

# Function to check for critical errors and restart if needed
check_for_critical_errors() {
    # Check for HTTP server binding error
    if journalctl -u wifi-connect.service --since "5 minutes ago" | grep -q "Cannot start HTTP server on '192.168.42.1:80': Cannot assign requested address"; then
        echo "Critical error detected: HTTP server binding failure"
        return 1
    fi
    
    # Check for DNSMasq interface error
    if journalctl -u wifi-connect.service --since "5 minutes ago" | grep -q "dnsmasq: unknown interface wlan0"; then
        echo "Critical error detected: DNSMasq interface error"
        return 1
    fi
    
    return 0
}

# Function to restart the system
restart_system() {
    echo "Critical network errors detected. Restarting system in 30 seconds..."
    echo "Restart reason: Network interface configuration issues"
    
    # Log the restart
    logger "wifi-connect-wrapper: Critical network errors detected, restarting system"
    
    # Wait 30 seconds then restart
    sleep 30
    sudo reboot
}

sleep 30

while true; do
    # Check for critical errors first
    if ! check_for_critical_errors; then
        ERROR_COUNT=$((ERROR_COUNT + 1))
        echo "Error count: $ERROR_COUNT/$MAX_ERROR_COUNT"
        
        if [ $ERROR_COUNT -ge $MAX_ERROR_COUNT ]; then
            restart_system
        fi
    else
        # Reset error count if no errors detected
        ERROR_COUNT=0
    fi
    
    # Rescan
    nmcli dev wifi rescan >/dev/null 2>&1

    # Check current SSID via NetworkManager
    CURRENT_SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)

    if [ -n "$CURRENT_SSID" ] && [ "$CURRENT_SSID" != "$WIFI_CONNECT_SSID" ]; then
        if pgrep -x "wifi-connect" > /dev/null; then
            echo "Connected to $CURRENT_SSID. Stopping wifi-connect..."
            pkill -x "wifi-connect"
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
