#!/bin/bash

##
## EPITECH PROJECT, 2025
## Epitech
## File description:
## coding-style-checker
##


function my_readlink() {
    cd "$1"
    pwd
    cd - > /dev/null
}

function cat_readme() {
    echo ""
    echo "Usage: $(basename "$0") [OPTIONS] DELIVERY_DIR REPORTS_DIR"
    echo ""
    echo "Arguments:"
    echo -e "\tDELIVERY_DIR\tPath to the directory containing your project files."
    echo -e "\tREPORTS_DIR\tPath to the directory where reports will be saved."
    echo ""
    echo "Options:"
    echo -e "\t-hs, --haskell DELIVERY_DIR \t(Optional) Run lambdananas on the specified Haskell directory."
    echo -e "\t--help\t\t\tShow this help message and exit."
    echo ""
    echo "Notes:"
    echo -e "\t- Running with the Haskell option (-hs)"
    echo -e "\t- Existing reports in the output directory will be overwritten."
    echo ""
    echo "© 2025 Epitech. Tous droits réservés."
}

LOCAL_BINARY="/usr/local/bin/"

function update_lambdananas() {
    echo "Updating lambdananas..."

    if ! command -v docker &> /dev/null; then
        echo "Error: Docker is not installed. Please install it and retry."
        echo "Use this link to search how to install docker on your pc : https://docs.docker.com/engine/install/ "
    fi

    if ! systemctl is-active --quiet docker; then
        echo " Error: Docker service is not running. Start it with: sudo systemctl start docker"
        read -p "Do you want to proceed? (yes/no) " yn
    case $yn in 
        yes | Y | y | Yes | YES) 
            sudo systemctl start docker
            ;;
        *) 
            echo "Skipping..."
            ;;
    esac
    fi

    IMAGE_NAME="ghcr.io/epitech/coding-style-checker:latest"
    if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
        echo "🔄 Downloading Docker image for lambdananas..."
        docker pull "$IMAGE_NAME" || { echo "❌ Failed to pull Docker image."; exit 1; }
    fi

    LAMBDA_PATH=$(sudo find /var/lib/docker/overlay2/ -name "lambdananas" 2>/dev/null | head -n 1)

    sudo cp "$LAMBDA_PATH" ./lambdananas

    if [[ ! -f "./lambdananas" ]]; then
        echo "Error: Failed to extract lambdananas from Docker."
        exit 1
    fi

    chmod +x lambdananas
    sudo mv lambdananas "$LOCAL_BINARY"

    echo "Lambdananas successfully updated!"
}

if ! command -v lambdananas &> /dev/null; then
    echo "⚠️  lambdananas not found. Installing via Docker..."
    update_lambdananas
fi

if [[ "$#" -eq 2 && ( "$1" == "-hs" || "$1" == "--haskell" ) ]]; then
    echo "📌 Detected Haskell file. Running lambdananas..."
    excluded_dirs="Setup.hs:setup.hs:.git:.stack-work:test:tests:bonus"
    lambdananas -o vera --exclude "$excluded_dirs" "$2"
    exit 0
fi

if [[ "$#" -eq 1 && "$1" == "--help" ]]; then
    cat_readme
    exit 0
fi

if [[ "$#" -ne 2 ]]; then
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
chown -R "$USER:$USER" "$REPORTS_DIR"
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

if [[ -n "$REMOTE_IMAGE_DATE" ]] && [[ -n "$LOCAL_IMAGE_DATE" ]]; then
    LOCAL_TIMESTAMP=$(date -d "$LOCAL_IMAGE_DATE" +%s 2>/dev/null || echo 0)
    REMOTE_TIMESTAMP=$(date -d "$REMOTE_IMAGE_DATE" +%s 2>/dev/null || echo 0)

    if [ "$REMOTE_TIMESTAMP" -gt "$LOCAL_TIMESTAMP" ]; then
        echo "Downloading new image and cleaning old one..."
        $BASE_EXEC_CMD pull "$IMAGE_NAME" && $BASE_EXEC_CMD image prune -f
        update_lambdananas
        echo "Download OK"
    fi
fi

tput setaf 2
echo "**/*/*/*/*/*/*/*/*/*/*/* CODING STYLE CHECKER EPITECH */*/*/*/*/*/*/*/*/*/*/*/**"
tput sgr0

$BASE_EXEC_CMD run --rm -i -v "$DELIVERY_DIR:/mnt/delivery" -v "$REPORTS_DIR:/mnt/reports" "$IMAGE_NAME" "/mnt/delivery" "/mnt/reports"

[[ -f "$EXPORT_FILE" ]] && echo "$(wc -l < "$EXPORT_FILE") coding style error(s) reported in "$EXPORT_FILE", $(tput sgr0; tput setaf 9; grep -c ": MAJOR:" "$EXPORT_FILE") major, $(tput sgr0; tput setaf 27; grep -c ": MINOR:" "$EXPORT_FILE") minor, $(tput sgr0; tput setaf 11; grep -c ": INFO:" "$EXPORT_FILE") info"
tput sgr0; echo ""

if [[ -f "/tmp/noge/coding-style-reports.log" ]]; then
    cat /tmp/noge/coding-style-reports.log
fi
