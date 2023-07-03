# Stable Diffusion Linux Script

This repository contains a bash script for setting up a stable diffusion environment on Linux. The script is designed to work with Ubuntu, Arch Linux, and Debian distributions.

## Features

- Detects the system's language and loads the appropriate localization file.
- Checks for necessary packages and installs them if they are not already installed.
- Clones the stable-diffusion-webui repository if it does not already exist.
- Checks the Python version and installs Python 3.10.6 if it is not already installed.
- Checks the pip version and upgrades it if necessary.
- Installs project dependencies from the requirements.txt file.
- Checks if xformers is installed and installs it if necessary.
- Edits webui-user.sh to include necessary command line arguments.
- Clones necessary extensions.
- Downloads model files from the ControlNet repository on HuggingFace.
- Downloads safetensor models, LoRA models, and embeddings based on user input.
- Starts webui-user.sh in a screen session.
- Starts ngrok in a screen session and prints the public URL.

## Usage

To use the script, clone this repository and run the script from the root directory:

```bash
git clone https://github.com/QuLOVE/SD-Linux-script.git
cd SD-Linux-script
./sd.sh
```

The script will prompt you to download various models. Enter `y` to download a model or `N` to skip it.

## Requirements

- Internet connection
- At least 80GB of free disk space
- Ubuntu, Arch Linux, or Debian distribution

## Note

This script is intended for use in a fresh environment. If you have already partially set up a stable diffusion environment, the script may not work as expected.
