#!/bin/bash

# Path to the ssh users log file
SSH_USERS_LOG=/var/log/ssh-users.log

# Email address of the administrator
ADMIN_EMAIL=d-grebenev@mail.ru

# Calculate the date three months ago
THREE_MONTHS_AGO=$(date -d "-3 months" +"%b %_d")

# Search for any users who haven't logged in for 3 months
INACTIVE_USERS=$(grep "Accepted publickey for" "$SSH_USERS_LOG" | awk '{print $1, $2}' | sort -u | awk -v tma="$THREE_MONTHS_AGO" '$2 < tma {print $1}')

# If there are any inactive users, send an email notification to the administrator
if [ -n "$INACTIVE_USERS" ]; then
    echo "The following ssh users haven't logged in for 3 months: $INACTIVE_USERS" | mailx -s "Inactive ssh users" "$ADMIN_EMAIL"
fi
