#!/bin/bash

# Path: this script
export SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"

timestamp() {
    date +"[%Y-%m-%d %H:%M:%S]"
}

add_log() {
    add="$1"
    stdbuf -oL -eL tee >(stdbuf -oL -eL awk -v prefix="$(timestamp)$add " '{ print prefix $0 }' >>"$(dirname "$0")/.sd_setting_env_shell.log") 2>&1
}
echo "!!![shell start]---------------------------------------------------------------------------------------------------"

# 将所有输出重定向到日志文件并在终端中显示
exec > >(add_log)

# 定义变量
WORKSPACE_PATH=$(pwd)
WEBUI_FOLDER_PATH="$WORKSPACE_PATH/stable-diffusion-webui"
WEBUI_MODELS_FOLDER_PATH="$WEBUI_FOLDER_PATH/models/Stable-diffusion"
WEBUI_VAE_FOLDER_PATH="$WEBUI_FOLDER_PATH/models/VAE"
WEBUI_CLIPS_FOLDER_PATH="$WEBUI_FOLDER_PATH/models/CLIP"
WEBUI_ControlNet_FOLDER_PATH="$WEBUI_FOLDER_PATH/models/ControlNet"
CONFIG_URL="https://gitcode.net/Akegarasu/sd-webui-configs/-/raw/master/config.json"

MODEL_URLS=(
    "https://huggingface.co/gsdf/Counterfeit-V2.5/resolve/main/Counterfeit-V2.5_fp16.safetensors"
    "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned.safetensors"
    "https://huggingface.co/andite/anything-v4.0/resolve/main/anything-v4.5.safetensors"
)
VAE_URLS=()
ControlNet_URLS=(
    "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11e_sd15_shuffle.pth"
    "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11f1e_sd15_tile.pth"
    "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11f1p_sd15_depth.pth"
    "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_canny.pth"
    "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_inpaint.pth"
    "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_lineart.pth"
    "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_mlsd.pth"
    "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_normalbae.pth"
    "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_openpose.pth"
    "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_scribble.pth"
    "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_seg.pth"
    "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_softedge.pth"
    "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15s2_lineart_anime.pth"
)
CLIP_URLS=()
REPO_URLS=(
    "https://gitcode.net/overbill1683/stablediffusion.git"
    "https://gitcode.net/overbill1683/taming-transformers.git"
    "https://gitcode.net/overbill1683/k-diffusion.git"
    "https://gitcode.net/overbill1683/CodeFormer.git"
    "https://gitcode.net/overbill1683/BLIP.git"
    "https://gitee.com/zwtnju/GFPGAN.git"
)
EXTENSION_URLS=(
    "https://gitcode.net/ranting8323/a1111-sd-webui-tagcomplete.git"
    "https://gitcode.net/ranting8323/stable-diffusion-webui-localization-zh_CN.git"
    "https://gitcode.net/ranting8323/sd-webui-additional-networks.git"
)

DIR_NAME_FROM_URL() {
    local repo_url="$1"
    echo "$repo_url" | sed 's/.*\/\([^/.]*\).*$/\1/'
}

FILE_NAME_FROM_URL() {
    local repo_url="$1"
    echo "$repo_url" | sed 's/.*\/\([^/]*\)$/\1/'
}

# 下载模型、子仓库和扩展
download_models() {
    loop() {
        for _url in "${MODEL_URLS[@]}"; do
            download_thead "$_url" "$1" &> >(add_log "[ASYNC] ") &
        done

    }
    loop &
}

download_VAE() {
    loop() {
        for _url in "${VAE_URLS[@]}"; do
            download_thead "$_url" "$1" &> >(add_log "[ASYNC] ") &
        done
    }
    loop &
}

download_ControlNet() {
    loop() {
        for _url in "${ControlNet_URLS[@]}"; do
            download_thead "$_url" "$1" &> >(add_log "[ASYNC] ") &
        done
    }
    loop &
}

download_repos() {
    mkdir -p "$WORKSPACE_PATH"/stable-diffusion-webui/repositories

    loop() {
        for repo_url in "${REPO_URLS[@]}"; do
            git clone "$repo_url" "$WORKSPACE_PATH"/stable-diffusion-webui/repositories/$(DIR_NAME_FROM_URL "$repo_url") &> >(add_log "[ASYNC] ") &
        done
    }
    loop &
}

download_extensions() {
    mkdir -p "$WORKSPACE_PATH"/stable-diffusion-webui/extensions
    loop() {
        for extension_url in "${EXTENSION_URLS[@]}"; do
            git clone "$extension_url" "$WORKSPACE_PATH"/stable-diffusion-webui/extensions/$(DIR_NAME_FROM_URL "$extension_url") &> >(add_log "[ASYNC] ") &
        done
    }
    loop &
}

download_thead() {
    local model_url="$1"
    local FIR="$2"
    mkdir -p "$FIR"
    aria2c --console-log-level=info -c -x 16 -s 64 -d "$FIR" -o $(FILE_NAME_FROM_URL "$model_url") "$model_url" &> >(add_log "[ASYNC] ") &
}

# 定义如何下载配置文件
profiles() {
    cd $WORKSPACE_PATH/stable-diffusion-webui
    wget -O "config.json" $CONFIG_URL
    chmod 755 config.json
}

env_set() {
    download_models $WEBUI_MODELS_FOLDER_PATH
    download_VAE $WEBUI_VAE_FOLDER_PATH
    download_ControlNet $WEBUI_ControlNet_FOLDER_PATH
    download_extensions
    download_repos
    
}

python_env(){
    bash -c '
        PIP_INDEX_URL="https://mirrors.bfsu.edu.cn/pypi/web/simple"
        GFPGAN_PACKAGE="git+https://gitee.com/zdevt/GFPGAN.git"
        CLIP_PACKAGE="git+https://gitee.com/zdevt/CLIP.git"
        OPENCLIP_PACKAGE="git+https://gitee.com/ufhy/open_clip.git"

        # 安装 Python 依赖
        python3 -m pip install --upgrade pip
        # 安装依赖
        pip3 install --index-url=$PIP_INDEX_URL $GFPGAN_PACKAGE $CLIP_PACKAGE $OPENCLIP_PACKAGE
    '
}

start() {
    # 启动服务
    set -e
    mv "$WORKSPACE_PATH"/stable-diffusion-webui/repositories/stablediffusion "$WORKSPACE_PATH"/stable-diffusion-webui/repositories/stable-diffusion-stability-ai
    cd $WORKSPACE_PATH/stable-diffusion-webui
    # 检查环境变量的值
    if [ "$ENV" = "cpu" ]; then
        # 执行 CPU 命令
        python3 launch.py --no-download-sd-model --skip-torch-cuda-test --use-cpu all --share --listen --no-half --no-half-vae &> >(add_log "[WEBUI] ")
    elif [ "$ENV" = "gpu" ]; then
        # 执行 GPU 命令
        python3 launch.py --no-download-sd-model --xformers --xformers-flash-attention --share --listen &> >(add_log "[WEBUI] ")
    else
        # 未指定环境变量时，输出错误信息并退出脚本
        echo "Error: ENV variable is not set."
        exit 1
    fi
}

# 安装依赖
apt-get update
apt-get install -y aria2 && apt-get upgrade -y

python_env &> >(add_log "[children] ")

git clone https://gitcode.net/overbill1683/stable-diffusion-webui $WEBUI_FOLDER_PATH
env_set
sleep 300
start
