#!/bin/bash

# just change the bark url
BARK_URL="https://xxxx.xxxx.xxxx/xxxxxxxx/Github/"

# Function to get the latest release version for a given owner/repo
get_latest_release() {
    local owner=$1
    local repo=$2
    local latest_release=$(curl -s "https://api.github.com/repos/$owner/$repo/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    echo "$latest_release"
}

# Function to check for updates and log the latest version for a given owner/repo
check_for_updates() {
    local owner=$1
    local repo=$2
    local latest_version=$(get_latest_release "$owner" "$repo")
    local log_file="${owner}_${repo}_version_log.txt"

    if [ -f "$log_file" ]; then
        local current_version=$(cat "$log_file")
        if [ "$current_version" != "$latest_version" ]; then
            echo "New version available for $owner/$repo: $latest_version"
            echo "$latest_version" > "$log_file"
            send_notification "$owner" "$repo"
        else
            echo "No updates available for $owner/$repo."
        fi
    else
        echo "$latest_version" > "$log_file"
        echo "Initial version recorded for $owner/$repo: $latest_version"
        send_notification "$owner" "$repo"
    fi
}

# Function to send notification to the specified URL
send_notification() {
    local owner=$1
    local repo=$2
    local message="Repository $owner/$repo has updates."
    local encoded_message=$(urlencode "$message")
    local url="${BARK_URL}${encoded_message}?group=Github&icon=https://github.githubassets.com/favicons/favicon.png"
    curl -s "$url"
}

# URL-encode function
urlencode() {
    local string=$1
    local length=${#string}
    local encoded=""
    local pos c o

    for ((pos = 0; pos < length; pos++)); do
        c=${string:$pos:1}
        case "$c" in
            [-_.~a-zA-Z0-9])
                o="${c}"
                ;;
            *)
                printf -v o '%%%02x' "'$c"
                ;;
        esac
        encoded+="${o}"
    done

    echo "${encoded}"
}


# Read owner/repo pairs from a file
read_owner_repos_from_file() {
    local file=$1
    local owner_repos=()
    while IFS= read -r owner_repo || [ -n "$owner_repo" ]; do
        IFS="/" read -ra parts <<< "$owner_repo"
        if [ "${#parts[@]}" -eq 2 ]; then
            check_for_updates "${parts[0]}" "${parts[1]}"
        else
            echo "Invalid input: $owner_repo"
        fi
    done < "$file"
}

# Parse command-line arguments
while getopts "c:" opt; do
    case $opt in
        c)
            file=$OPTARG
            read_owner_repos_from_file "$file"
            ;;
        *)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# Run the script
