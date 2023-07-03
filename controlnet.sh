#!/bin/bash

# Define ControlNet models and their URLs
declare -A controlnet=(
    ["control_v11e_sd15_ip2p.pth"]="https://huggingface.co/lllyasviel/ControlNet-v1-1/blob/main/control_v11e_sd15_ip2p.pth"
    ["control_v11e_sd15_shuffle.pth"]="https://huggingface.co/lllyasviel/ControlNet-v1-1/blob/main/control_v11e_sd15_shuffle.pth"
    ["control_v11f1e_sd15_tile.pth"]="https://huggingface.co/lllyasviel/ControlNet-v1-1/blob/main/control_v11f1e_sd15_tile.pth"
    ["control_v11f1p_sd15_depth.pth"]="https://huggingface.co/lllyasviel/ControlNet-v1-1/blob/main/control_v11f1p_sd15_depth.pth"
    ["control_v11p_sd15_canny.pth"]="https://huggingface.co/lllyasviel/ControlNet-v1-1/blob/main/control_v11p_sd15_canny.pth"
    ["control_v11p_sd15_inpaint.pth"]="https://huggingface.co/lllyasviel/ControlNet-v1-1/blob/main/control_v11p_sd15_inpaint.pth"
    ["control_v11p_sd15_lineart.pth"]="https://huggingface.co/lllyasviel/ControlNet-v1-1/blob/main/control_v11p_sd15_lineart.pth"
)
