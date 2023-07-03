# Stable Diffusion Linux Script

这个资源库包含一个bash脚本，用于在Linux上建立一个稳定的Stable Diffusion环境。 该脚本适用于Ubuntu和Debian发行版。

## 特点

- 检测系统的语言并加载适当的本地化文件。
- 检查必要的软件包，如果还没有安装，则安装它们。
- 克隆 stable-diffusion-webui 仓库，如果它还不存在的话。
- 检查Python版本，如果还没有安装，则安装Python 3.10.6。
- 检查pip的版本，如果需要的话，将其升级。
- 从requirements.txt文件中安装项目的依赖性。
- 检查是否安装了xformers，如有必要，将其安装。
- 编辑webui-user.sh，加入必要的命令行参数。
- 克隆必要的扩展。
- 从 HuggingFace 上的 ControlNet 仓库下载模型文件。
- 下载安全传感器模型、LoRA模型，以及基于用户输入的嵌入文件。
- 在屏幕会话中启动 webui-user.sh。
- 在屏幕会话中启动ngrok并打印出公共URL。

## 使用方法

要使用这个脚本，请克隆这个资源库并在根目录下运行该脚本：

```bash
git clone https://github.com/QuLOVE/SD-Linux-script.git
cd SD-Linux-script
./sd.sh
```

该脚本会提示你下载各种模型。输入 "y "来下载一个模型，或者输入 "N "来跳过它。

## 要求

- 互联网连接
- 至少80GB的可用磁盘空间
- Ubuntu 或 Debian 发行版
