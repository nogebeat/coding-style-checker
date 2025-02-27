#!/bin/bash

function my_readlink() {
    cd "$1" || exit
    pwd
    cd - > /dev/null
}

function cat_readme() {
    echo ""
    echo "Usage: $(basename "$0") DELIVERY_DIR REPORTS_DIR [HASKELL_FILE]"
    echo -e "\tDELIVERY_DIR\tShould be the directory where your project files are"
    echo -e "\tREPORTS_DIR\tShould be the directory where we output the reports"
    echo -e "\tHASKELL_FILE\t(Optional) If a Haskell file is provided, it will be checked with lambdananas"
    echo -e "\t\t\tTake note that existing reports will be overridden"
    echo ""
}

IMAGE_HASKELL="ghcr.io/nogebeat/lambdananas:latest"
LOCAL_BINARY="/usr/local/bin/lambdananas"

if ! command -v lambdananas &> /dev/null; then
    echo "lambdananas not found. Installing via Docker..."

    docker run --rm --entrypoint cat "$IMAGE_HASKELL" /usr/local/bin/lambdananas > lambdananas
    chmod +x lambdananas
    sudo mv lambdananas "$LOCAL_BINARY"

    if ! command -v lambdananas &> /dev/null; then
        echo "Installation failed."
        exit 1
    fi
fi


if [ "$#" -eq 1 ] && [[ "$1" == *.hs ]]; then
    echo "Detected Haskell file. Running lambdananas..."
    lambdananas "$1"
    exit 0
fi

if [ "$#" == 1 ] && [ "$1" == "--help" ]; then
    cat_readme
    exit 0
fi

if [ "$#" -ne 2 ]; then
    cat_readme
    exit 1
fi

mkdir -p /tmp/noge/
DELIVERY_DIR=$(my_readlink "$1")
REPORTS_DIR=/tmp/noge/
DOCKER_SOCKET_PATH=/var/run/docker.sock
HAS_SOCKET_ACCESS=$(test -r "$DOCKER_SOCKET_PATH"; echo "$?")
IMAGE_NAME="ghcr.io/epitech/coding-style-checker:latest"
EXPORT_FILE="/tmp/noge/coding-style-reports.log"
BASE_EXEC_CMD="docker"

rm -f "$EXPORT_FILE"
chown -R $USER:$USER "$REPORTS_DIR"
chmod -R 777 "$REPORTS_DIR"

if [ "$HAS_SOCKET_ACCESS" -ne 0 ]; then
    echo "WARNING: Socket access is denied"
    echo "To fix this, add the current user to the docker group: sudo usermod -a -G docker $USER"
    read -p "Do you want to proceed? (yes/no) " yn
    case $yn in 
        yes | Y | y | Yes | YES) 
            sudo usermod -a -G docker "$USER"
            echo "You must reboot your computer for the changes to take effect."
            ;;
        *) 
            echo "Skipping..."
            ;;
    esac
    BASE_EXEC_CMD="sudo ${BASE_EXEC_CMD}"
fi

LOCAL_IMAGE_DATE=$(docker inspect --format='{{.Created}}' "$IMAGE_NAME" 2>/dev/null)
REMOTE_IMAGE_DATE=$(curl -sI "https://ghcr.io/v2/epitech/coding-style-checker/manifests/latest" | grep -i "last-modified" | cut -d' ' -f2-)

if [ -z "$LOCAL_IMAGE_DATE" ] || [ "$(date -d "$REMOTE_IMAGE_DATE" +%s)" -gt "$(date -d "$LOCAL_IMAGE_DATE" +%s)" ]; then
    echo "Downloading new image and cleaning old one..."
    $BASE_EXEC_CMD pull "$IMAGE_NAME" && $BASE_EXEC_CMD image prune -f
    echo "Download OK"
    tput setaf 2
    echo "**/*/*/*/*/*/*/*/*/*/*/* CODING STYLE CHECKER EPITECH */*/*/*/*/*/*/*/*/*/*/*/**"
    tput sgr0
else
    tput setaf 1
fi

$BASE_EXEC_CMD run --rm -i -v "$DELIVERY_DIR:/mnt/delivery" -v "$REPORTS_DIR:/mnt/reports" "$IMAGE_NAME" "/mnt/delivery" "/mnt/reports"

[[ -f "$EXPORT_FILE" ]] && echo "$(wc -l < "$EXPORT_FILE") coding style error(s) reported in "$EXPORT_FILE", $(tput sgr0; tput setaf 9; grep -c ": MAJOR:" "$EXPORT_FILE") major, $(tput sgr0; tput setaf 27; grep -c ": MINOR:" "$EXPORT_FILE") minor, $(tput sgr0; tput setaf 11; grep -c ": INFO:" "$EXPORT_FILE") info"
tput setaf 2
if [[ -f "/tmp/noge/coding-style-reports.log" ]]; then
    cat /tmp/noge/coding-style-reports.log
fi
