#!/bin/bash

# 定义 Rust 安装的位置
RUSTUP_HOME="$HOME/.rustup"
CARGO_HOME="$HOME/.cargo"
LOG_FILE="$HOME/rust_install.log"

# 将输出记录到文件和控制台
exec > >(tee -a "$LOG_FILE") 2>&1

# 加载 Rust 环境变量
load_rust() {
    export RUSTUP_HOME="$HOME/.rustup"
    export CARGO_HOME="$HOME/.cargo"
    export PATH="$CARGO_HOME/bin:$PATH"
    if [ -f "$HOME/.cargo/env" ]; then
        source "$HOME/.cargo/env"
    fi
}

# 安装 Rust 所需的系统依赖
install_dependencies() {
    echo "正在安装 Rust 所需的系统依赖..."
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y build-essential libssl-dev curl
    elif command -v yum &> /dev/null; then
        sudo yum groupinstall 'Development Tools' && sudo yum install -y openssl-devel curl
    elif command -v dnf &> /dev/null; then
        sudo dnf groupinstall 'Development Tools' && sudo dnf install -y openssl-devel curl
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu base-devel openssl curl
    elif command -v brew &> /dev/null; then
        echo "检测到 MacOS，使用 Homebrew 安装依赖..."
        brew install openssl curl
    else
        echo "不支持的包管理器，请手动安装依赖。"
        exit 1
    fi
}

# 在检查 Rust 之前安装系统依赖
install_dependencies

# 检查 Rust 是否已安装
if command -v rustup &> /dev/null; then
    echo "Rust 已安装。"
    read -p "是否要重新安装或更新 Rust？（y/n）： " choice
    if [[ "$choice" == "y" ]]; then
        echo "警告：重新安装 Rust 将删除您当前的设置。"
        read -p "您确定要继续吗？（y/n）： " confirm
        if [[ "$confirm" == "y" ]]; then
            echo "正在重新安装 Rust..."
            rustup self uninstall -y
            if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
                echo "错误：Rust 安装失败。正在退出。"
                exit 1
            fi
        else
            echo "重新安装已取消。"
            exit 0
        fi
    fi
else
    echo "Rust 未安装。正在安装 Rust..."
    if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
        echo "错误：Rust 安装失败。正在退出。"
        exit 1
    fi
fi

# 安装后加载 Rust 环境
load_rust 

# 修复 Rust 目录的权限
echo "确保 Rust 目录的权限正确..."
chmod -R 755 "$RUSTUP_HOME"
chmod -R 755 "$CARGO_HOME"

# 尝试重新加载环境以查找 Cargo
retry_cargo() {
    local max_retries=3
    local retry_count=0
    local cargo_found=false

    while [ $retry_count -lt $max_retries ]; do
        if command -v cargo &> /dev/null; then
            cargo_found=true
            break
        else
            echo "当前会话未找到 Cargo。尝试重新加载环境（第 $((retry_count + 1))/$max_retries 次）..."
            source "$HOME/.cargo/env"
            retry_count=$((retry_count + 1))
            sleep 1  # 在重试之间添加延迟
        fi
    done

    if [ "$cargo_found" = false ]; then
        echo "错误：经过 $max_retries 次尝试后，Cargo 仍未被识别。"
        echo "请手动加载环境：运行 source \$HOME/.cargo/env"
        return 1
    fi

    echo "当前会话中可用 Cargo。"
    return 0
}

# 获取当前 shell 的配置文件
get_profile() {
    if [[ $SHELL == *"zsh"* ]]; then
        echo "$HOME/.zshrc"
    else
        echo "$HOME/.bashrc"
    fi
}

PROFILE=$(get_profile)

# 将 Rust 环境变量添加到相应的 shell 配置文件
if ! grep -q "CARGO_HOME" "$PROFILE"; then
    echo "正在将 Rust 环境变量添加到 $PROFILE..."
    {
        echo 'export RUSTUP_HOME="$HOME/.rustup"'
        echo 'export CARGO_HOME="$HOME/.cargo"'
        echo 'export PATH="$CARGO_HOME/bin:$PATH"'
        echo 'source "$HOME/.cargo/env"'
    } >> "$PROFILE"
else
    echo "Rust 环境变量已存在于 $PROFILE。"
fi

# 自动重新加载配置文件以适应当前会话
source "$PROFILE"

# 强制重新加载 Cargo 环境
source "$HOME/.cargo/env"

# 重试检查 Cargo 是否可用
retry_cargo
if [ $? -ne 0 ]; then
    exit 1
fi

# 验证 Rust 和 Cargo 版本
rust_version=$(rustc --version)
cargo_version=$(cargo --version)

echo "Rust 版本：$rust_version"
echo "Cargo 版本：$cargo_version"

echo "Rust 安装和设置完成！"

