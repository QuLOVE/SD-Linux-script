#!/bin/bash

# Detecting language
lang=$(locale | grep LANG | cut -d= -f2 | cut -d_ -f1)

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

# Define models and their IDs
source ./safetensor_models.sh
source ./lora_models.sh
source ./embeddings.sh
source ./extensions.sh
source ./controlnet.sh

# Function to download models
download_models() {
    local models=$1
    local folder=$2
    mkdir -p "$folder"
    cd "$folder"
    for id in "${!models[@]}"; do
        read -p "$DOWNLOAD_PROMPT ${models[$id]}? [y/N] " answer
        if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
            wget "https://civitai.com/api/download/models/$id" --content-disposition
        fi
    done
    cd ..
}

if [[ $PWD != $HOME ]]; then
    echo -e "${RED}$RUN_FROM_ROOT${NC}"
    exit 1
fi

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
else
    echo -e "${RED}$NO_OS_RELEASE${NC}"
    exit 1
fi

if ! ping -c 1 github.com &> /dev/null; then
    echo -e "${RED}$NO_INTERNET${NC}"
    exit 1
fi

AVAILABLE_DISK_SPACE=$(df / | tail -1 | awk '{print $4}')
REQUIRED_DISK_SPACE=80000000
if (( AVAILABLE_DISK_SPACE < REQUIRED_DISK_SPACE )); then
    echo -e "${RED}$NOT_ENOUGH_SPACE${NC}"
    exit 1
fi

for pkg in curl wget git screen ngrok jq; do
    if ! command -v $pkg &> /dev/null; then
        echo -e "${RED}$pkg $PKG_NOT_FOUND${NC}"
        if [[ "$OS" == "Ubuntu" ]]; then
            sudo apt-get install $pkg -y
        elif [[ "$OS" == "Arch Linux" ]]; then
            sudo pacman -S $pkg --noconfirm
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

# Check Python version and install/upgrade if necessary
if command -v python3 &> /dev/null; then
    version=$(python3 -V 2>&1 | grep -Po '(?<=Python )(.+)')
    if [[ "$version" < "3.10.6" ]]; then
        echo -e "${RED}$PYTHON_LESS_THAN${NC}"
    else
        echo -e "${GREEN}$PYTHON_INSTALLED${NC}"
    fi
else
    echo -e "${RED}$PYTHON_NOT_FOUND${NC}"
fi

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
fi

# Install project dependencies
cd stable-diffusion-webui
if [ -f "requirements.txt" ]; then
    pip3 install -r requirements.txt
    if [ $? -ne 0 ]; then
        echo -e "${RED}$FAILED_TO_INSTALL_PYTHON_DEPS${NC}"
        exit 1
    fi
else
    echo -e "${RED}$REQUIREMENTS_NOT_FOUND${NC}"
    exit 1
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
else
    echo -e "${RED}$WEBUI_USER_NOT_FOUND${NC}"
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui/
    if [ $? -ne 0 ]; then
        echo -e "${RED}$FAILED_TO_CLONE_SD_WEBUI${NC}"
        exit 1
    fi
fi

# Clone extensions
cd ../extensions
for ext in "${!extensions[@]}"; do
    if [ ! -d "$ext" ]; then
        git clone "${extensions[$ext]}"
    fi
done

# Download model files from ControlNet repository on HuggingFace
cd sd-webui-controlnet/models
for model in "${!controlnet[@]}"; do
    if [ ! -f "$model" ]; then
        curl -L -o "$model" "${controlnet[$model]}"
    fi
done

# Return to the root directory
cd $HOME

# Download models
read -p "$DOWNLOAD_SAFETENSOR_MODELS? [y/N] " answer
if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    download_models "$models" "stable-diffusion-webui/models/Stable-diffusion"
fi

read -p "$DOWNLOAD_LORA_MODELS? [y/N] " answer
if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    download_models "$lora_models" "stable-diffusion-webui/models/LoRA"
fi

read -p "$DOWNLOAD_EMBEDDINGS? [y/N] " answer
if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    download_models "$embeddings" "stable-diffusion-webui/models/Embeddings"
fi

# Start webui-user.sh in a screen session
screen -dmS SD bash -c 'cd stable-diffusion-webui; ./webui-user.sh'

# Start ngrok in a screen session and print the public URL
screen -dmS ngrok bash -c 'ngrok http 7860'
sleep 5
public_url=$(curl --silent --max-time 10 --connect-timeout 5 http://127.0.0.1:4040/api/tunnels | jq --raw-output '.tunnels[0].public_url')
echo -e "${GREEN}$PUBLIC_URL: $public_url${NC}"

echo -e "${GREEN}$ALL_TASKS_COMPLETED${NC}"
