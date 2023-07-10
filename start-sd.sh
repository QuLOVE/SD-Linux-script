#!/bin/bash

# Loading localization file
case $lang in
  "ja")
    source ./locales/ja.sh
    ;;
  "zh")
    source ./locales/zh.sh
    ;;
  *)
    source ./locales/en.sh
    ;;
esac

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$MUST_BE_ROOT${NC}"
   exit 1
fi

AVAILABLE_DISK_SPACE=$(df / | tail -1 | awk '{print $4}')
REQUIRED_DISK_SPACE=80000000
if (( AVAILABLE_DISK_SPACE < REQUIRED_DISK_SPACE )); then
    echo -e "${RED}$NOT_ENOUGH_SPACE${NC}"
    exit 1
fi

# Update package lists for upgrades and new package installations
apt-get update

# Function to check and install necessary packages
check_install_packages() {
    for pkg in $1; do
        if ! command -v $pkg &> /dev/null; then
            echo -e "${RED}$pkg $PKG_NOT_FOUND${NC}"
            apt-get install $pkg -y
        else
            echo -e "${GREEN}$pkg $PKG_INSTALLED${NC}"
        fi
    done
}

# Function to check and install necessary python version
check_python_version() {
    python_version=$(python3.10 -V 2>&1 | grep -Po '(?<=Python )(.+)' || echo "Not Found")
    if [[ "$python_version" != "3.10"* ]]; then
        if command -v python3 &> /dev/null; then
            apt-get remove -y python3
        fi
        apt-get install -y python3.10
    fi
    # Check if python3.10 command exists and then make python command refer to python3.10
    if command -v python3.10 &> /dev/null; then
        update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1
    fi
}

# Detecting language
lang=$(locale | grep LANG | cut -d= -f2 | cut -d_ -f1)

# Check for Python 3.10 and install if necessary
check_python_version

required_packages="curl wget git screen jq"
check_install_packages "$required_packages"

# Define models and their IDs or URLs
source ./safetensor_models.sh
source ./lora_models.sh
source ./embeddings.sh
source ./extensions.sh
source ./controlnet.sh
source ./upscalers.sh

# Check pip version and install/upgrade if necessary
if command -v pip3 &> /dev/null; then
    pip_version=$(pip3 -V | cut -d " " -f 2)
    if [[ "$pip_version" < "21.0" ]]; then
        echo -e "${RED}$PIP_LESS_THAN${NC}"
        pip3 install --upgrade pip
    else
        echo -e "${GREEN}$PIP_UP_TO_DATE${NC}"
    fi
else
    echo -e "${RED}$PIP_NOT_FOUND${NC}"
    apt-get install python3-pip -y
fi

# Download and install ngrok
if [ ! -f "/usr/local/bin/ngrok" ]; then
    wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
    tar xf ngrok-v3-stable-linux-amd64.tgz
    sudo mv ngrok /usr/local/bin
    rm ngrok-v3-stable-linux-amd64.tgz
fi

if [ ! -f /root/.config/ngrok/ngrok.yml ]; then
    echo -e "${RED}$NGROK_NOT_FOUND${NC}"
    read -p "$ENTER_NGROK " ngrok_config
fi

download_models() {
    declare -A models=$1
    local path=$2
    local from=$3

    # Check for existing of folder with models
    if [ ! -d "$path" ]; then
        mkdir -p "$path"
    fi

    for id in "${!models[@]}"; do
        local file
        local url

        if [ "$from" == "civitai" ]; then
            url="https://civitai.com/api/download/models/${id}"
            local filename=$(wget --server-response --spider $url 2>&1 | awk -F"filename=" '/filename=/{print $2}' | tr -d '\r')
            file="${path}/${filename}"
        else
            url="${models[$id]}"
            file="${path}/${id}"
        fi

        if [ ! -f "$file" ]; then
            echo "Downloading ${models[$id]}..."
            if [ "$from" == "civitai" ]; then
                wget --content-disposition -P "$path" "$url"
            else
                wget -O "$file" -L "$url"
            fi
        fi
    done
}

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
else
    echo -e "${RED}$NO_OS_RELEASE${NC}"
    exit 1
fi

for pkg in curl wget git screen jq; do
    if ! command -v $pkg &> /dev/null; then
        echo -e "${RED}$pkg $PKG_NOT_FOUND${NC}"
        if [[ "$OS" == "Ubuntu" ]]; then
            sudo apt-get install $pkg -y
        elif [[ "$OS" == "Debian GNU/Linux" ]]; then
            sudo apt-get install $pkg -y
        else
            echo -e "${RED}$UNSUPPORTED_DISTRIBUTION${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}$pkg $PKG_INSTALLED${NC}"
    fi
done

# Clone the stable-diffusion-webui repository
if [ ! -d "stable-diffusion-webui" ]; then
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui/
else
    echo -e "${GREEN}$SD_EXISTS${NC}"
fi

# Install project dependencies
cd stable-diffusion-webui
if [ -f "requirements.txt" ]; then
    pip3 install -r requirements.txt
    if [ $? -ne 0 ]; then
        echo -e "${RED}$FAILED_TO_INSTALL_PYTHON_DEPS${NC}"
        exit 1
    fi
fi

# Check if xformers is installed
if ! python3 -c "import xformers" &> /dev/null; then
    echo -e "${RED}$XFORMERS_NOT_FOUND${NC}"
    # Build xformers
    source ./venv/bin/activate
    cd repositories
    git clone https://github.com/facebookresearch/xformers.git
    cd xformers
    git submodule update --init --recursive
    pip install -r requirements.txt
    pip install -e .
    if [ $? -ne 0 ]; then
        echo -e "${RED}$FAILED_TO_INSTALL_XFORMERS${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}$XFORMERS_INSTALLED${NC}"
fi

# Edit webui-user.sh
if [ -f "../webui-user.sh" ]; then
    if grep -q "COMMANDLINE_ARGS=\"--xformers --share\"" "../webui-user.sh"; then
        echo -e "${GREEN}$WEBUI_USER_CORRECT${NC}"
    else
        sed -i 's/export COMMANDLINE_ARGS=""/export COMMANDLINE_ARGS="--xformers --share"/g' ../webui-user.sh
        if [ $? -ne 0 ]; then
            echo -e "${RED}$FAILED_TO_UPDATE_WEBUI_USER${NC}"
            exit 1
        else
            echo -e "${GREEN}$UPDATED_WEBUI_USER${NC}"
        fi
    fi
fi

# Return to the root directory
cd $HOME

# Download models
download_models "$safetensors" "stable-diffusion-webui/models/stable-diffusion" "civitai"
download_models "$embeddings" "stable-diffusion-webui/embeddings" "civitai"
download_models "$lora_models" "stable-diffusion-webui/models/lora" "civitai"
download_models "$upscalers" "stable-diffusion-webui/models/ESRGAN" "huggingface"
download_models "$controlnet" "stable-diffusion-webui/extensions/sd-webui-controlnet/models" "huggingface"

# Start webui-user.sh in a screen session
screen -dmS SD bash -c 'cd stable-diffusion-webui; ./webui-user.sh'

# Start ngrok in a screen session and print the public URL
screen -dmS ngrok bash -c 'ngrok http 7860'
sleep 10
public_url=$(wget -qO- http://127.0.0.1:4040/api/tunnels | jq --raw-output '.tunnels[0].public_url')
echo -e "${GREEN}$PUBLIC_URL: $public_url${NC}"

echo -e "${GREEN}$ALL_TASKS_COMPLETED${NC}"
