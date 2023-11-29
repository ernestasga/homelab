#!/bin/bash

# Define a list of system-reserved, read-only variables
readonly RESERVED_VARS=("UID" "GID" "EUID" "EGID" "PWD" "HOME" "IFS")

# Function to apply templating
# Arguments: $1 - Template file path
#            $2 - Associative array name
apply_template() {
    local template_file=$1
    local -n replacements=$2
    local temp_file=$(mktemp)

    cp "$template_file" "$temp_file"

    for key in "${!replacements[@]}"; do
        sed -i "s/{{$key}}/${replacements[$key]}/g" "$temp_file"
    done

    echo "$temp_file"
}
# Function to check if a variable is reserved
is_reserved_var() {
    for rv in "${RESERVED_VARS[@]}"; do
        if [[ $rv == $1 ]]; then
            return 0 # 0 is true in bash script
        fi
    done
    return 1 # 1 is false
}

# Load .env file if it exists
if [[ -f .env ]]; then
    echo "Loading .env file"
    while IFS='=' read -r key value; do
        if [[ ! -z "$key" && ! "$key" =~ ^# ]]; then
            if is_reserved_var "$key"; then
                echo "WARNING: Attempt to set reserved variable $key in .env is ignored"
            else
                export "$key"="$value"
            fi
        fi
    done < .env
fi



# First, check if all the required environment variables are set
REQUIRED_ENV_VARS=(
    "CONTAINER_DATA_PATH"
    "DUCKDNS_EMAIL"
    "DUCKDNS_SUBDOMAINS"
    "DUCKDNS_FULL_DOMAIN"
    "DUCKDNS_TOKEN"
)
for ENV_VAR in "${REQUIRED_ENV_VARS[@]}"; do
    if [[ -z "${!ENV_VAR}" ]]; then
        echo "ERROR: Environment variable ${ENV_VAR} is not set!"
        exit 1
    fi
done



# Next, create the required directories for the containers, if they don't exist
REQUIRED_CONTAINER_DIRS=(
    "${CONTAINER_DATA_PATH}/portainer"
    "${CONTAINER_DATA_PATH}/mosquito"
    "${CONTAINER_DATA_PATH}/zigbee2mqtt"
    "${CONTAINER_DATA_PATH}/homeassistant"
    "${CONTAINER_DATA_PATH}/traefik"
    "${CONTAINER_DATA_PATH}/plex"
    "${CONTAINER_DATA_PATH}/jellyseerr"
    "${CONTAINER_DATA_PATH}/radarr"
    "${CONTAINER_DATA_PATH}/sonarr"
    "${CONTAINER_DATA_PATH}/prowlarr"
    "${CONTAINER_DATA_PATH}/transmission"
)
for DIR in "${REQUIRED_CONTAINER_DIRS[@]}"; do
    if [[ ! -d "${DIR}" ]]; then
        echo "Creating directory ${DIR}"
        mkdir -p "${DIR}"
    fi
done



# Finally, create the required files for the containers, if they don't exist
EMPTY_TRAFFIK_FILES=(
    "${CONTAINER_DATA_PATH}/traefik/acme.json"
    "${CONTAINER_DATA_PATH}/traefik/config.yml"
)
for FILE in "${EMPTY_TRAFFIK_FILES[@]}"; do
    if [[ ! -f "$FILE" ]]; then
        echo "Creating file $FILE"
        touch "$FILE"
    fi
done
# Ensure acme.json has the right permissions
chmod 600 "${CONTAINER_DATA_PATH}/traefik/acme.json"

# Create traefik.yml from template
TRAEFIK_TEMPLATE="./templates/traefik/traefik.yml.duckdns.temlate"
TRAEFIK_CONFIG="${CONTAINER_DATA_PATH}/traefik/traefik.yml"

declare -A TRAEFIK_REPLACEMENTS=(
    ["EMAIL"]="${DUCKDNS_EMAIL}"
)
temp_file=$(apply_template "$TRAEFIK_TEMPLATE" TRAEFIK_REPLACEMENTS)
cp "$temp_file" "$TRAEFIK_CONFIG"

# Create config.yml from template
CONFIG_TEMPLATE="./templates/traefik/config.yml.duckdns.temlate"
CONFIG_FILE="${CONTAINER_DATA_PATH}/traefik/config.yml"

declare -A CONFIG_REPLACEMENTS=(
    ["DUCKDNS_FULL_DOMAIN"]="${DUCKDNS_FULL_DOMAIN}"
    ["_3DPRINTER_AUTH_1"]="${_3DPRINTER_USER_1}"
    ["_3DPRINTER_AUTH_2"]="${_3DPRINTER_USER_2}"
    ["_3DPRINTER_IP"]="${_3DPRINTER_IP}"
)
temp_file=$(apply_template "$CONFIG_TEMPLATE" CONFIG_REPLACEMENTS)
cp "$temp_file" "$CONFIG_FILE"