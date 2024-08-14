#!/bin/bash

# Telegram bot token and chat ID
TELEGRAM_BOT_TOKEN="<YOUR-DATA>"
TELEGRAM_CHAT_ID="<YOUR-DATA>"

# Function to send message to Telegram
send_telegram_message() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d "chat_id=$TELEGRAM_CHAT_ID&text=$message" > /dev/null
}

# Function to check epoch
check_epoch() {
    current_epoch=$(/root/.local/share/solana/install/active_release/bin/solana epoch)
    if [[ "$current_epoch" != "$last_epoch" ]]; then
        last_epoch="$current_epoch"
        return 0 # Epoch changed
    else
        return 1 # Epoch not changed
    fi
}

# Main loop
while true; do
    # Check epoch
    if check_epoch; then
        message="Epoch changed. Running splsp update..."
        echo "$message"
        send_telegram_message "$message"

        # Run update command until "Update not required"
        while true; do
            result=$(/root/sanctum-spl-stake-pool-cli/target/debug/splsp update EYwMHf8Ajnpvy3PqMMkq1MPkTyhCsBEesXFgnK9BZfmu 2>&1)
            sleep 120
            echo "Result: $result"
            send_telegram_message "Result of splsp update: $result"

            # Check if result contains "Update not required"
            if echo "$result" | grep -q "Update not required"; then
                message="Update successful. Resuming epoch check..."
                echo "$message"
                send_telegram_message "$message"
                break  # Break inner loop and resume epoch check
            fi

            sleep 1  # Add a small delay between retries
        done
    else
        echo "Epoch not changed. Waiting..."
        sleep 27  # Wait for 27 seconds before checking epoch again
    fi
done