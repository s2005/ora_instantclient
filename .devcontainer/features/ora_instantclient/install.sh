#!/bin/bash

# Fail script on any error
set -e

VERSION=${VERSION:-"latest"}

if [ "$(id -u)" -ne 0 ]; then
	echo 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
	exit 1
fi

ARCH="$(uname -m)"
if [ "${ARCH}" != "x86_64" ] ; then
	echo -e "unsupported arch: ${ARCH}"
	exit 1
fi

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

# Simple libaio fix for Ubuntu 24.04
install_libaio() {
    echo "Installing libaio with Ubuntu 24.04 compatibility..."
    apt_get_update
    
    # Try libaio1t64 first (Ubuntu 24.04), fallback to libaio1 (older versions)
    if apt-cache policy libaio1t64 | grep -q "Candidate:" && ! apt-cache policy libaio1t64 | grep -q "Candidate: (none)"; then
        apt-get -y install --no-install-recommends libaio1t64 libaio-dev
        echo "Installed libaio1t64 and libaio-dev"
        
        # Create symbolic link for Oracle compatibility
        if [ -f "/usr/lib/x86_64-linux-gnu/libaio.so.1t64" ] && [ ! -f "/usr/lib/x86_64-linux-gnu/libaio.so.1" ]; then
            ln -s /usr/lib/x86_64-linux-gnu/libaio.so.1t64 /usr/lib/x86_64-linux-gnu/libaio.so.1
            echo "Created libaio.so.1 -> libaio.so.1t64 symbolic link"
        fi
    else
        # Fallback for older Ubuntu versions
        apt-get -y install --no-install-recommends libaio1 libaio-dev
        echo "Installed libaio1 and libaio-dev"
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

create_instantclient_symlinks() {
    local oracle_home="$1"
    local client_version="$2"

    if [[ "${client_version%%.*}" -lt 18 ]]; then
        echo "Creating symbolic links for Oracle Instant Client version prior to 18.3..."
        cd "${oracle_home}"

        # Check if the target files exist before creating the symbolic links
        if [ -f "libclntsh.so.${client_version}" ]; then
            ln -sf "libclntsh.so.${client_version}" "libclntsh.so"
        else
            echo "WARNING: Target file libclntsh.so.${client_version} not found."
        fi

        if [ -f "libocci.so.${client_version}" ]; then
            ln -sf "libocci.so.${client_version}" "libocci.so"
        else
            echo "WARNING: Target file libocci.so.${client_version} not found."
        fi
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
    wget -P /tmp --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" "$download_url" >&2

    # Return the filename of the downloaded file for future processing if the download was successful.
    if [[ $? -eq 0 ]]; then  # Check if wget was successful.
        echo "/tmp/${filename}"
    else
        echo "Download of ${download_url} failed!" >&2
        return 1  # Return an error code if the download failed.
    fi
}

echo "Activating feature 'ora_instantclient'"
export DEBIAN_FRONTEND=noninteractive

# Install libaio with Ubuntu 24.04 compatibility
install_libaio

# Install other required packages
check_packages unzip wget

filename=$(download_oracle_client "${VERSION}")
echo "Downloaded - ${filename}"

target_path=/opt/oracle
# make sure target_path exists
mkdir -p "${target_path}"

# Extract the zip file and capture the subfolder name
subfolder=$(extract_zip_to_path "${filename}" "$target_path")
ret_value=$?

if [ $ret_value -eq 0 ]; then
    ORACLE_HOME="${target_path}/${subfolder}"
    echo "Extraction completed to ${ORACLE_HOME}"

    # Add the path to PATH and LD_LIBRARY_PATH
    updaterc "$(cat << EOF
export ORACLE_HOME="${ORACLE_HOME}"
if [[ "\${PATH}" != *"\${ORACLE_HOME}"* ]]; then export PATH="\${PATH}:\${ORACLE_HOME}"; fi
EOF
)"

    updaterc "$(cat << EOF
if [[ "\${LD_LIBRARY_PATH}" != *"\${ORACLE_HOME}"* ]]; then export LD_LIBRARY_PATH="\${LD_LIBRARY_PATH}:\${ORACLE_HOME}"; fi
EOF
)"

    # Extract major and minor version (e.g., 12.1) from the filename using regex
    client_major_minor_version=$(echo "$subfolder" | grep -oP 'instantclient_(\d+_\d+)' | cut -d'_' -f 2,3 | tr '_' '.')

    # Add the call to the new create_instantclient_symlinks function after setting ORACLE_HOME
    create_instantclient_symlinks "${ORACLE_HOME}" "${client_major_minor_version}"

    echo "${ORACLE_HOME}" > /etc/ld.so.conf.d/oracle-instantclient.conf
    ldconfig
fi

clean_up

echo "Done!"
