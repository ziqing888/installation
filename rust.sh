#!/bin/bash

# Define the location where Rust will be installed
RUSTUP_HOME="$HOME/.rustup"
CARGO_HOME="$HOME/.cargo"
LOG_FILE="$HOME/rust_install.log"

# Log output to a file and console simultaneously
exec > >(tee -a "$LOG_FILE") 2>&1

# Load Rust environment variables
load_rust() {
    export RUSTUP_HOME="$HOME/.rustup"
    export CARGO_HOME="$HOME/.cargo"
    export PATH="$CARGO_HOME/bin:$PATH"
    if [ -f "$HOME/.cargo/env" ]; then
        source "$HOME/.cargo/env"
    fi
}

# Function to install system dependencies required for Rust
install_dependencies() {
    echo "Installing system dependencies required for Rust..."
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y build-essential libssl-dev curl
    elif command -v yum &> /dev/null; then
        sudo yum groupinstall 'Development Tools' && sudo yum install -y openssl-devel curl
    elif command -v dnf &> /dev/null; then
        sudo dnf groupinstall 'Development Tools' && sudo dnf install -y openssl-devel curl
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu base-devel openssl curl
    elif command -v brew &> /dev/null; then
        echo "MacOS detected. Installing dependencies using Homebrew..."
        brew install openssl curl
    else
        echo "Unsupported package manager. Please install dependencies manually."
        exit 1
    fi
}

# Install system dependencies before checking for Rust
install_dependencies

# Check if Rust is already installed
if command -v rustup &> /dev/null; then
    echo "Rust is already installed."
    read -p "Do you want to reinstall or update Rust? (y/n): " choice
    if [[ "$choice" == "y" ]]; then
        echo "Warning: Reinstalling Rust will remove your current setup."
        read -p "Are you sure you want to continue? (y/n): " confirm
        if [[ "$confirm" == "y" ]]; then
            echo "Reinstalling Rust..."
            rustup self uninstall -y
            if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
                echo "Error: Rust installation failed. Exiting."
                exit 1
            fi
        else
            echo "Reinstallation aborted."
            exit 0
        fi
    fi
else
    echo "Rust is not installed. Installing Rust..."
    if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
        echo "Error: Rust installation failed. Exiting."
        exit 1
    fi
fi

# Load Rust environment after installation
load_rust 

# Fix permissions for Rust directories
echo "Ensuring correct permissions for Rust directories..."
chmod -R 755 "$RUSTUP_HOME"
chmod -R 755 "$CARGO_HOME"

# Function to retry sourcing environment if Cargo is not found
retry_cargo() {
    local max_retries=3
    local retry_count=0
    local cargo_found=false

    while [ $retry_count -lt $max_retries ]; do
        if command -v cargo &> /dev/null; then
            cargo_found=true
            break
        else
            echo "Cargo not found in the current session. Attempting to reload the environment (try $((retry_count + 1))/$max_retries)..."
            source "$HOME/.cargo/env"
            retry_count=$((retry_count + 1))
            sleep 1  # Adding a delay between retries
        fi
    done

    if [ "$cargo_found" = false ]; then
        echo "Error: Cargo is still not recognized after $max_retries attempts."
        echo "Please manually source the environment by running: source \$HOME/.cargo/env"
        return 1
    fi

    echo "Cargo is available in the current session."
    return 0
}

# Get the profile file for the current shell
get_profile() {
    if [[ $SHELL == *"zsh"* ]]; then
        echo "$HOME/.zshrc"
    else
        echo "$HOME/.bashrc"
    fi
}

PROFILE=$(get_profile)

# Add Rust environment variables to the appropriate shell profile
if ! grep -q "CARGO_HOME" "$PROFILE"; then
    echo "Adding Rust environment variables to $PROFILE..."
    {
        echo 'export RUSTUP_HOME="$HOME/.rustup"'
        echo 'export CARGO_HOME="$HOME/.cargo"'
        echo 'export PATH="$CARGO_HOME/bin:$PATH"'
        echo 'source "$HOME/.cargo/env"'
    } >> "$PROFILE"
else
    echo "Rust environment variables are already present in $PROFILE."
fi

# Reload the profile automatically for the current session
source "$PROFILE"

# Force reload of cargo env in case the session doesn’t reflect it yet
source "$HOME/.cargo/env"

# Retry checking for Cargo availability
retry_cargo
if [ $? -ne 0 ]; then
    exit 1
fi

# Verify Rust and Cargo versions
rust_version=$(rustc --version)
cargo_version=$(cargo --version)

echo "Rust version: $rust_version"
echo "Cargo version: $cargo_version"

echo "Rust installation and setup are complete!"
