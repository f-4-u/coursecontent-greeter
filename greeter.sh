#!/bin/bash

# Greeter Script
# This script greets users, logs their greetings, and displays relevant information.
# Author: f-4-u
# Date: February 5, 2024

# Exit Codes:
# 0: Successful execution
# 1: Another instance of the script is running
# 2: Error creating or accessing lock or log file
# 3: No username provided
# 4: User does not exist on the system
# 5: Script execution failed
# 6: Script help menu was shown

# Default locations
DEFAULT_LOG_FILE="$HOME/greetings.log"
DEFAULT_LOCK_FILE="/tmp/greeter.lock"

# Set default values
LOG_FILE="$DEFAULT_LOG_FILE"
LOCK_FILE="$DEFAULT_LOCK_FILE"

# Global variable to store sudo permissions result
sudo_result=false

# Arrays to store special and ordinary users
SPECIAL_USERS=()
ORDINARY_USERS=()


# Function to display script usage
show_usage() {
    echo "Usage: $0 [-l <log_file>] [-lk <lock_file>] [-h] [username1] [username2] ..."
    echo "Options:"
    echo "  -l <log_file>    Specify custom log file location (default: $DEFAULT_LOG_FILE)"
    echo "  -k <lock_file>  Specify custom lock file location (default: $DEFAULT_LOCK_FILE)"
    echo "  -h               Show this help message"

    exit 6
}

# Process command-line options
while getopts "l:k:h" opt; do
    case $opt in
    l)
        LOG_FILE="$OPTARG"
        ;;
    k)
        LOCK_FILE="$OPTARG"
        ;;
    h)
        show_usage
        ;;
    \?)
        show_usage
        ;;
    esac
done

# Shift the options so that $1, $2, ... contain the remaining arguments (usernames)
shift "$((OPTIND - 1))"

# Example: Print log and lock file paths and remaining arguments (usernames)
echo "Log File: $LOG_FILE"
echo "Lock File: $LOCK_FILE"

# Check if another instance of the script is running
if [ -e "$LOCK_FILE" ]; then
    echo "Error: Another instance of the script is running." >&2
    exit 1
fi

# Create lock file
if [ ! -e "$LOCK_FILE" ]; then
    if ! /usr/bin/touch "$LOCK_FILE"; then
        echo "Error: Unable to create or access the lock file $LOCK_FILE." >&2
        exit 2
    fi
    /usr/bin/chmod 600 "$LOCK_FILE"
fi

# Check if the log file exists, create one if not
if [ ! -e "$LOG_FILE" ]; then
    if ! /usr/bin/touch "$LOG_FILE"; then
        echo "Error: Unable to create or access the log file $LOG_FILE." >&2
        rm_lock
        exit 2
    fi
    /usr/bin/chmod 600 "$LOG_FILE"
fi

# Function to remove the lock file upon exit
rm_lock() {
    trap 'rm -f "$LOCK_FILE"' EXIT
}

# Function to check if the user has sudo permissions
check_sudo_permissions() {
    local username="$1"
    sudo_result=$(sudo -n -lU "$username" 2>/dev/null)
}

# Function to check if a user exists on the system and belongs to specified groups
user_exists_and_in_groups() {
    local username="$1"
    local groups=("adm" "root" "sudo" "wheel")

    # Check if the user exists on the system
    if /usr/bin/id "$username" &>/dev/null; then
        # Check if the user belongs to one of the specified groups
        for group in "${groups[@]}"; do
            if /usr/bin/id -nG "$username" | /usr/bin/grep -qw "${group,,}"; then
                if ! [[ " ${SPECIAL_USERS[@]} " =~ " $username " ]]; then
                    SPECIAL_USERS+=("$username") # Add to special users array if not already present
                fi
                return 0 # User exists and is in one of the specified groups
            fi
        done
        if ! [[ " ${ORDINARY_USERS[@]} " =~ " $username " ]]; then
            ORDINARY_USERS+=("$username") # Add to ordinary users array if not already present
        fi
        return 1 # User exists but is not in any of the specified groups
    else
        return 2 # User does not exist on the system
    fi
}

# Function to validate users
validate_users() {
    local username="$1"

    # Check if the user exists on the system and is in specified groups
    user_exists_and_in_groups "$username"
}

# Function to log greetings with Unix timestamps
log_greeting() {
    local username="$1"
    echo "$(/usr/bin/date '+%s'):$username" >>"$LOG_FILE"
}

# Function to get the last greeting for a user from the log file
get_last_greeting() {
    local username="$1"
    local last_greeting="$(
        /usr/bin/grep "$username" "$LOG_FILE" |
            /usr/bin/tail -n 1 |
            /usr/bin/cut -d ':' -f1 |
            /usr/bin/sed 's/^ *//'
    )"

    if [ ! -z "$last_greeting" ]; then
        local locale_time
        locale_time=$(/usr/bin/date -d "@$last_greeting" '+%c' --utc)
        echo "$locale_time"
    else
        echo "$(/usr/bin/date '+%c' --utc)" # fake return if last_greeting is empty, but log will be created after get_last_greeting
    fi
}

# Function to show groups if the user has sudo permissions
show_groups_perm() {
    local username="$1"

    # Check if the user has sudo permissions
    check_sudo_permissions "$username"

    if [ -n "$sudo_result" ]; then
        echo "$(/usr/bin/groups "$username")"
    else
        echo "..."
    fi
}

# Function to generate a greeting message
greet_user() {
    local username="$1"

    # Check if the user exists on the system and is in specified groups
    user_exists_and_in_groups "$username"
    local result="$?"

    local last_greeting
    last_greeting=$(get_last_greeting "$username")

    if [ "$result" -eq 0 ]; then
        echo "Hello $username! Your last greeting was: $last_greeting. You belong to a special group ( $(show_groups_perm "$username") )."
    elif [ "$result" -eq 1 ]; then
        echo "Hello $username! Your last greeting was: $last_greeting. You exist but do not belong to any special group."
    else
        echo "User $username does not exist on the system."
    fi

    # Log the greeting
    log_greeting "$username"
}

# Check if at least one username is provided as a command-line argument
if [ "$#" -eq 0 ]; then
    echo "No usernames provided as arguments."

    # Prompt the user for a username
    read -rp "Separate multiple usernames with spaces: " USER_INPUT # Use read -r to read input without interpreting backslashes

    # Test if the string is not empty
    if [[ -n "$USER_INPUT" ]]; then
        # Split the string into an array of usernames
        IFS=" " read -ra usernames <<<"$USER_INPUT"

        # Loop through the provided usernames
        for username in "${usernames[@]}"; do
            validate_users "${username,,}"
        done
    else
        echo "No username provided!"
        rm_lock
        exit 3
    fi
else
    # Loop through the provided usernames
    for username in "$@"; do
        validate_users "${username,,}"
    done
fi

# Sort the arrays alphabetically
IFS=$'\n' SPECIAL_USERS=($(sort -u <<<"${SPECIAL_USERS[*]}"))
IFS=$'\n' ORDINARY_USERS=($(sort -u <<<"${ORDINARY_USERS[*]}"))

# Greet special users first
for username in "${SPECIAL_USERS[@]}"; do
    greet_user "$username"
done

# Greet ordinary users next
for username in "${ORDINARY_USERS[@]}"; do
    greet_user "$username"
done

rm_lock
exit 0
