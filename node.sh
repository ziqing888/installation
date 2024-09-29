#!/bin/bash

# 设置 NVM 目录
NVM_DIR="$HOME/.nvm"

# 加载 NVM 到环境中
load_nvm() {
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        . "$NVM_DIR/nvm.sh"  # 加载 nvm
        export PATH="$NVM_DIR/versions/node/$(nvm version)/bin:$PATH"  # 将 node 和 npm 添加到 PATH 中
    else
        echo "错误：NVM 未正确安装。正在退出..."
        exit 1
    fi
}

# 如果没有找到 NVM，则安装 NVM
install_nvm() {
    echo "未找到 NVM。正在安装 NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
    load_nvm  # 在当前 shell 中重新加载 NVM
}

# 确保必要的构建工具可用（gcc、make）
install_build_tools() {
    if ! command -v gcc &> /dev/null || ! command -v make &> /dev/null; then
        echo "正在安装所需的构建工具..."
        sudo apt update && sudo apt install -y build-essential
    fi
}

# 如果未找到 Node.js 和 npm，通过 NVM 安装它们
install_node_npm() {
    if ! command -v node &> /dev/null; then
        echo "未找到 Node.js。正在使用 NVM 安装最新版本..."
        nvm install node
    fi

    echo "Node.js 版本：$(node -v)"
    echo "npm 版本：$(npm -v)"
}

# 将 NVM 添加到 shell 配置文件，以便将来会话使用
setup_nvm_for_future_shells() {
    shell_config_files=("$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile")
    for config_file in "${shell_config_files[@]}"; do
        if [ -f "$config_file" ] && ! grep -q "NVM_DIR" "$config_file"; then
            echo "正在将 NVM 添加到 $config_file..."
            {
                echo 'export NVM_DIR="$HOME/.nvm"'
                echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
                echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'
            } >> "$config_file"
        fi
    done
}

# 在当前会话中加载 shell 配置文件
source_shell_files() {
    shell_files=("$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile")
    for shell_file in "${shell_files[@]}"; do
        [ -f "$shell_file" ] && . "$shell_file"
    done
}

# 检查 nvm、node 和 npm 是否可用
check_commands() {
    for cmd in nvm node npm; do
        if ! command -v $cmd &> /dev/null; then
            echo "错误：$cmd 无法访问。请检查安装。"
            exit 1
        fi
    done
    echo "nvm、node 和 npm 已成功加载。"
}

# 主逻辑，处理 root 用户和非 root 用户
main() {
    # 检查是否以 root 身份运行
    if [ "$EUID" -eq 0 ]; then
        echo "以 root 用户身份运行。"
        NVM_DIR="/root/.nvm"
    else
        echo "以非 root 用户身份运行。"
    fi

    # 检查 NVM 是否已安装，如果未安装则进行安装
    if [ ! -d "$NVM_DIR" ]; then
        install_nvm
    else
        echo "NVM 已经安装。"
        load_nvm
    fi

    # 确保构建工具已安装
    install_build_tools
    # 如果 Node.js 和 npm 不可用，则进行安装
    install_node_npm
    # 为未来的 shell 会话设置 NVM
    setup_nvm_for_future_shells
    # 在当前会话中加载 shell 文件
    source_shell_files
    # 检查 nvm、node 和 npm 是否可用
    check_commands
    # 调试输出以验证 PATH
    echo "当前 PATH：$PATH"
    echo "NVM 目录：$NVM_DIR"
    echo "Node.js 路径：$(command -v node)"
    echo "npm 路径：$(command -v npm)"
    echo "NVM、Node.js 和 npm 设置已完成，适用于当前和未来的 shell。"
}

# 运行主函数
main
sleep 10
source ~/.bashrc

