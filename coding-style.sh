#!/bin/bash
 
##
## EPITECH PROJECT, 2025
## Epitech
## File description:
## coding-style-checker
##
 
BASE_EXEC_CMD="docker"
 
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
 
 
if [[ "$#" -eq 1 && "$1" == "--help" ]]; then
    cat_readme
    exit 0
fi
 
if [[ "$#" -gt 2 ]]; then
    cat_readme
    exit 1
fi
 
REPORTS_DIR=$(my_readlink .)
EXPORT_FILE="$REPORTS_DIR"/coding-style-reports.log
 
function pull_docker() {
    DELIVERY_DIR=$(my_readlink "$1")
    DOCKER_SOCKET_PATH="/var/run/docker.sock"
    HAS_SOCKET_ACCESS=$(test -r "$DOCKER_SOCKET_PATH"; echo "$?")
    IMAGE_NAME="ghcr.io/epitech/coding-style-checker:latest"
    #EXPORT_FILE="/tmp/noge/coding-style-reports.log"
 
    rm -f "$EXPORT_FILE"
    #chown -R "$USER:$USER" "$REPORTS_DIR"
    #chmod -R 777 "$REPORTS_DIR"
 
    if [[ "$HAS_SOCKET_ACCESS" -ne 0 ]]; then
        echo "WARNING: Socket access is denied"
        echo "To fix this, add the current user to the docker group: sudo usermod -a -G docker $USER"
        read -rp "Do you want to proceed? (yes/no) " yn
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
 
    if [[ -n "$REMOTE_IMAGE_DATE" && -n "$LOCAL_IMAGE_DATE" ]]; then
        LOCAL_TIMESTAMP=$(date -d "$LOCAL_IMAGE_DATE" +%s 2>/dev/null || echo 0)
        REMOTE_TIMESTAMP=$(date -d "$REMOTE_IMAGE_DATE" +%s 2>/dev/null || echo 0)
 
        if [[ "$REMOTE_TIMESTAMP" -gt "$LOCAL_TIMESTAMP" ]]; then
            echo "Downloading new image and cleaning old one..."
            $BASE_EXEC_CMD pull "$IMAGE_NAME" && $BASE_EXEC_CMD image prune -f
            echo "Download OK"
        fi
    fi
}
 
tput setaf 2
echo "**/*/*/*/*/*/*/*/*/*/*/* CODING STYLE CHECKER EPITECH */*/*/*/*/*/*/*/*/*/*/*/**"
tput sgr0
 
if [[ "$#" -eq 2 && ( "$1" == "-hs" || "$1" == "--haskell" ) ]]; then
    echo ""
    echo "📌 Running Haskell Coding Style ..."
    echo ""
 
    pull_docker "$2"
 
    HASKELL_DIR=$(my_readlink "$2")
 
    excluded_dirs="Setup.hs:setup.hs:.git:.stack-work:test:tests:bonus"
 
    LAMBDA_PATH=$($BASE_EXEC_CMD run --rm --entrypoint /bin/bash ghcr.io/epitech/coding-style-checker:latest -c "which lambdananas")
 
    # $BASE_EXEC_CMD run --rm --entrypoint /bin/bash ghcr.io/epitech/coding-style-checker:latest -c "which lambdananas"
    $BASE_EXEC_CMD run --rm  --entrypoint $LAMBDA_PATH -v "$HASKELL_DIR:/mnt/haskell" "$IMAGE_NAME" "/mnt/haskell"
    exit 0
fi
 
if [[ "$#" -eq 2 || "$#" -eq 1 ]]; then
    echo ""
    echo "📌 Running C Coding Style ..."
    echo ""
 
    pull_docker "$1"
 
    $BASE_EXEC_CMD run --rm -i -v "$DELIVERY_DIR:/mnt/delivery" -v "$REPORTS_DIR:/mnt/reports" "$IMAGE_NAME" "/mnt/delivery" "/mnt/reports"
 
    #$BASE_EXEC_CMD run --rm --security-opt "label:disable" -i -v "$DELIVERY_DIR":"/mnt/delivery" -v "$REPORTS_DIR":"/mnt/reports" ghcr.io/epitech/coding-style-checker:latest "/mnt/delivery" "/mnt/reports"
    [[ -f "$EXPORT_FILE" ]] && echo "$(wc -l < "$EXPORT_FILE") coding style error(s) reported in "$EXPORT_FILE", $(tput sgr0; tput setaf 9; grep -c ": MAJOR:" "$EXPORT_FILE") major, $(tput sgr0; tput setaf 27; grep -c ": MINOR:" "$EXPORT_FILE") minor, $(tput sgr0; tput setaf 11; grep -c ": INFO:" "$EXPORT_FILE") info"
    tput sgr0; echo ""
 
    if [[ -f "./coding-style-reports.log" ]]; then
        cat ./coding-style-reports.log
	rm -f ./coding-style-reports.log
    fi
fi
