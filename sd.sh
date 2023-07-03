#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Define models and their IDs
declare -A models=(
    ["80511"]="MeinaMix v10 (Anime)"
    ["106922"]="Hassaku v1.3 (Anime WARN)"
    ["17233"]="AbyssOrangeMix3 (Anime)"
    ["105924"]="CetusMix_WhaleFall2 (Anime)"
    ["93208"]="Dark Sushi Mix 2.25D (Anime)"
    ["100675"]="MeinaValai V4 (Anime WARN)"
    ["57618"]="Counterfeit-V3.0 (Anime)"
    ["90854"]="Anything V5/Ink (Anime)"
    ["77276"]="Perfect World v4 Baked (Mix WARN)"
    ["5036"]="AbyssOrangeMix2 ZPPP (Anime WARN)"
    ["8474"]="AbyssOrangeMix2 ZPPP Inpaint (Anime WARN)"
    ["93901"]="NexusMix new concep (Anime)"
)

declare -A lora_models=(
    ["102533"]="Instant photo 拍立得/Polaroid LoRA & LoHA (3D)"
    ["62833"]="Detail Tweaker LoRA (细节调整LoRA) (Mix)"
)

declare -A embeddings=(
    ["20068"]="badhandv4 (Mix)"
)

# Function to download models
download_models() {
    local models=$1
    local folder=$2
    mkdir -p "$folder"
    cd "$folder"
    for id in "${!models[@]}"; do
        read -p "Download ${models[$id]}? [y/N] " answer
        if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
            wget "https://civitai.com/api/download/models/$id" --content-disposition
        fi
    done
    cd ..
}

# Check if the script is run from the root directory
if [[ $PWD != $HOME ]]; then
    echo -e "${RED}Please run this script from the root directory.${NC}"
    exit 1
fi

# Check the Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
else
    echo -e "${RED}Not running a distribution with /etc/os-release available${NC}"
    exit 1
fi

# Check for internet connection
if ! ping -c 1 google.com &> /dev/null; then
    echo -e "${RED}Internet connection not found. Please ensure you are connected to the internet before running this script.${NC}"
    exit 1
fi

# Check for sufficient disk space (100GB in this case)
AVAILABLE_DISK_SPACE=$(df / | tail -1 | awk '{print $4}')
REQUIRED_DISK_SPACE=100000000
if (( AVAILABLE_DISK_SPACE < REQUIRED_DISK_SPACE )); then
    echo -e "${RED}Not enough disk space. Please ensure you have at least 1GB of free disk space.${NC}"
    exit 1
fi

# Check for and install dependencies
for pkg in curl wget git screen ngrok; do
    if ! command -v $pkg &> /dev/null; then
        echo -e "${RED}$pkg could not be found, installing...${NC}"
        if [[ "$OS" == "Ubuntu" ]]; then
            sudo apt-get install $pkg -y
        elif [[ "$OS" == "Arch Linux" ]]; then
            sudo pacman -S $pkg --noconfirm
        elif [[ "$OS" == "Debian GNU/Linux" ]]; then
            sudo apt-get install $pkg -y
        else
            echo "Unsupported distribution"
            exit 1
        fi
    else
        echo -e "${GREEN}$pkg is installed${NC}"
    fi
done

# Clone the stable-diffusion-webui repository
if [ ! -d "stable-diffusion-webui" ]; then
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui/
else
    echo -e "${GREEN}stable-diffusion-webui already exists${NC}"
fi

# Check Python version and install/upgrade if necessary
if command -v python3 &> /dev/null; then
    version=$(python3 -V 2>&1 | grep -Po '(?<=Python )(.+)')
    if [[ "$version" < "3.10.6" ]]; then
        echo -e "${RED}Python is installed but the version is less than 3.10.6, upgrading...${NC}"
        # Add commands to upgrade Python here
    else
        echo -e "${GREEN}Python 3.10.6 is installed${NC}"
    fi
else
    echo -e "${RED}Python could not be found, installing Python 3.10.6...${NC}"
    # Add commands to install Python here
fi

# Check pip version and upgrade if necessary
pip_version=$(pip3 -V | cut -d " " -f 2)
if [[ "$pip_version" < "21.0" ]]; then
    echo -e "${RED}pip is installed but the version is less than 21.0, upgrading...${NC}"
    pip3 install --upgrade pip
else
    echo -e "${GREEN}pip is up-to-date${NC}"
fi

# Install project dependencies
cd stable-diffusion-webui
pip3 install -r requirements.txt

# Build xformers
source ./venv/bin/activate
cd repositories
git clone https://github.com/facebookresearch/xformers.git
cd xformers
git submodule update --init --recursive
pip install -r requirements.txt
pip install -e .

# Edit webui-user.sh
if [ -f "../webui-user.sh" ]; then
    if grep -q "COMMANDLINE_ARGS=\"--xformers --share\"" "../webui-user.sh"; then
        echo -e "${GREEN}webui-user.sh already contains the correct COMMANDLINE_ARGS${NC}"
    else
        sed -i 's/export COMMANDLINE_ARGS=""/export COMMANDLINE_ARGS="--xformers --share"/g' ../webui-user.sh
        echo -e "${GREEN}Updated COMMANDLINE_ARGS in webui-user.sh${NC}"
    fi
else
    echo -e "${RED}webui-user.sh not found${NC}"
    exit 1
fi

# Clone extensions
cd ../extensions
if [ ! -d "sd-dynamic-thresholding" ]; then
    git clone https://github.com/mcmonkeyprojects/sd-dynamic-thresholding
fi
if [ ! -d "stable-diffusion-webui-composable-lora" ]; then
    git clone https://github.com/opparco/stable-diffusion-webui-composable-lora
fi
if [ ! -d "depthmap2mask-update" ]; then
    git clone https://github.com/474172261/depthmap2mask-update
fi
if [ ! -d "sd-face-editor" ]; then
    git clone https://github.com/ototadana/sd-face-editor.git
fi
if [ ! -d "a1111-sd-webui-lycoris" ]; then
    git clone https://github.com/KohakuBlueleaf/a1111-sd-webui-lycoris
fi
if [ ! -d "sd-webui-controlnet" ]; then
    git clone https://github.com/Mikubill/sd-webui-controlnet.git
fi
if [ ! -d "sd-webui-depth-lib" ]; then
    git clone https://github.com/jexom/sd-webui-depth-lib.git
fi
if [ ! -d "depthmap2mask-update" ]; then
    git clone https://github.com/474172261/depthmap2mask-update
fi
if [ ! -d "posex" ]; then
    git clone https://github.com/hnmr293/posex
fi
if [ ! -d "sd-webui-roop-unlock" ]; then
    git clone https://github.com/QuLOVE/sd-webui-roop-unlock
fi


# Download model files from ControlNet repository on HuggingFace
cd sd-webui-controlnet/models
if [ ! -f "control_v11e_sd15_ip2p.pth" ]; then
    curl -L -o control_v11e_sd15_ip2p.pth https://huggingface.co/lllyasviel/ControlNet-v1-1/blob/main/control_v11e_sd15_ip2p.pth
fi
if [ ! -f "control_v11e_sd15_shuffle.pth" ]; then
    curl -L -o control_v11e_sd15_shuffle.pth https://huggingface.co/lllyasviel/ControlNet-v1-1/blob/main/control_v11e_sd15_shuffle.pth
fi
if [ ! -f "control_v11f1e_sd15_tile.pth" ]; then
    curl -L -o control_v11f1e_sd15_tile.pth https://huggingface.co/lllyasviel/ControlNet-v1-1/blob/main/control_v11f1e_sd15_tile.pth
fi
if [ ! -f "control_v11f1p_sd15_depth.pth" ]; then
    curl -L -o control_v11f1p_sd15_depth.pth https://huggingface.co/lllyasviel/ControlNet-v1-1/blob/main/control_v11f1p_sd15_depth.pth
fi
if [ ! -f "control_v11p_sd15_canny.pth" ]; then
    curl -L -o control_v11p_sd15_canny.pth https://huggingface.co/lllyasviel/ControlNet-v1-1/blob/main/control_v11p_sd15_canny.pth
fi
if [ ! -f "control_v11p_sd15_inpaint.pth" ]; then
    curl -L -o control_v11p_sd15_inpaint.pth https://huggingface.co/lllyasviel/ControlNet-v1-1/blob/main/control_v11p_sd15_inpaint.pth
fi
if [ ! -f "control_v11p_sd15_lineart.pth" ]; then
    curl -L -o control_v11p_sd15_lineart.pth https://huggingface.co/lllyasviel/ControlNet-v1-1/blob/main/control_v11p_sd15_lineart.pth
fi

# Return to the root directory
cd $HOME

# Download models
read -p "Download safetensor models? [y/N] " answer
if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    download_models "$models" "stable-diffusion-webui/models/Stable-diffusion"
fi

read -p "Download LoRA models? [y/N] " answer
if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    download_models "$lora_models" "stable-diffusion-webui/models/LoRA"
fi

read -p "Download embeddings? [y/N] " answer
if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    download_models "$embeddings" "stable-diffusion-webui/models/Embeddings"
fi

# Copy this script to the stable diffusion directory
cp $0 stable-diffusion-webui/

# Start webui-user.sh in a screen session
screen -dmS SD bash -c 'cd stable-diffusion-webui; ./webui-user.sh'

# Start ngrok in a screen session
screen -dmS ngrok bash -c 'ngrok http 7860'

echo -e "${GREEN}All tasks completed successfully.${NC}"
