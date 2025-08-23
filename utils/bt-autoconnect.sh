#!/bin/bash

DEVICE_MAC="A1:E0:00:A9:B4:3C"

while true; do
    STATUS=$(bluetoothctl info "$DEVICE_MAC" | grep "Connected:" | awk '{print $2}')

    if [ "$STATUS" == "no" ]; then
        echo "$(date): Device not connected. Trying to connect..."
        bluetoothctl connect "$DEVICE_MAC"

        # wait a bit before re-checking
        sleep 5
    else
        echo "$(date): Device is connected."
        # check every 30 seconds when connected
        sleep 30
    fi
done
