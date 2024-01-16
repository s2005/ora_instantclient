#!/bin/bash

# Fail script on any error
set -e

VERSION=${VERSION:-"latest"}

apt_get_update() {
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

clean_up() {
    rm -rf /var/lib/apt/lists/*
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends  "$@"
    fi
}

if ! grep -q -E "debian|ubuntu" /etc/os-release; then
    echo "This Feature is only supported on Debian-based distros."
    exit 0
fi

updaterc() {
	if grep -q "alpine" /etc/os-release; then
		echo "Updating /etc/profile"
		echo -e "$1" >>/etc/profile
	fi
	if [[ "$(cat /etc/bash.bashrc)" != *"$1"* ]]; then
		echo "Updating /etc/bash.bashrc"
		echo -e "$1" >>/etc/bash.bashrc
	fi
	if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh/zshrc)" != *"$1"* ]]; then
		echo "Updating /etc/zsh/zshrc"
		echo -e "$1" >>/etc/zsh/zshrc
	fi
}

# Function to convert version number from 'xx.xx.x.x.x' to 'xxxxxxx'.
convert_version() {
    local version="$1"
    # Remove dots.
    echo "${version//./}"
}

# Function that finds the name of the subfolder that matches the regex /instantclient.+/
get_subfolder_name() {
    local zipfile="$1"
    # List contents and extract folder name matching the pattern "instantclient" followed by anything.
    unzip -l "$zipfile" | grep -Eo 'instantclient[^/]*/' | head -n 1 | tr -d '/'
}

# Function to extract the zip file to a specified path and return the subfolder name.
extract_zip_to_path() {
    local zipfile="$1"
    local extract_path="$2"
    # Get the subfolder name using the get_subfolder_name function.
    local subfolder_name
    subfolder_name=$(get_subfolder_name "$zipfile")

    # Check if the subfolder_name has been set, then proceed to extraction.
    if [[ -n "$subfolder_name" ]]; then
        # Extract the ZIP file to the specified path.
        unzip -q -d "$extract_path" "$zipfile"
        echo "$subfolder_name"
    else
        echo "Could not determine the subfolder name from the ZIP file." >&2
        return 1
    fi
}

# Function to download oracle instant client using the provided or latest version number.
download_oracle_client() {
    local version_input="$1"

    local base_url="https://download.oracle.com/otn_software/linux/instantclient"
    local download_url=""
    local converted_version=""
    local filename=""

    if [[ "$version_input" == "latest" ]]; then
        # Use the default download URL when no specific version is provided or if the input is 'latest'.
        filename="instantclient-basic-linuxx64.zip"
        download_url="${base_url}/${filename}"
    else
        # Convert the provided version number and use it to construct the download URL.
        converted_version=$(convert_version "$version_input")
        filename="instantclient-basic-linux.x64-${version_input}dbru.zip"
        download_url="${base_url}/${converted_version}/${filename}"
    fi

    # Use wget to download the file.
    echo "Downloading from: $download_url" >&2
    wget -P /tmp --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" "$download_url"

    # Return the filename of the downloaded file for future processing if the download was successful.
    if [[ $? -eq 0 ]]; then  # Check if wget was successful.
        echo "/tmp/${filename}"
    else
        echo "Download failed." >&2
        return 1  # Return an error code if the download failed.
    fi
}

echo "Activating feature 'ora_instantclient'"
# apt-get install -y libaio1
export DEBIAN_FRONTEND=noninteractive
check_packages \
    unzip \
    wget

filename=$(download_oracle_client "${VERSION}")
echo "Downloaded - ${filename}"

target_path=/opt/oracle
# make sure target_path exists
mkdir -p "${target_path}"

# Extract the zip file and capture the subfolder name
INSTANT_CLIENT_PATH=$(extract_zip_to_path "${filename}" "$target_path")
ret_value=$?

if [ $ret_value -eq 0 ]; then
    echo "Extraction completed to ${target_path}/${INSTANT_CLIENT_PATH}"
    # Add the subfolder's path to PATH and LD_LIBRARY_PATH
    # export PATH="$PATH:${target_path}/${INSTANT_CLIENT_PATH}"
    # export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${target_path}/${INSTANT_CLIENT_PATH}"
	updaterc "if [[ \"\${PATH}\" != *\"\${INSTANT_CLIENT_PATH}\"* ]]; then export PATH=\"\${INSTANT_CLIENT_PATH}:\${PATH}\"; fi"
	updaterc "if [[ \"\${LD_LIBRARY_PATH}\" != *\"\${INSTANT_CLIENT_PATH}\"* ]]; then export LD_LIBRARY_PATH=\"\${INSTANT_CLIENT_PATH}:\${LD_LIBRARY_PATH}\"; fi"
fi

clean_up

echo "Done!"
