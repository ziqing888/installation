#!/bin/bash

# Set NVM directory
NVM_DIR="$HOME/.nvm"

# Function to load NVM into the environment
load_nvm() {
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        . "$NVM_DIR/nvm.sh"  # Load nvm
        export PATH="$NVM_DIR/versions/node/$(nvm version)/bin:$PATH"  # Add node and npm to PATH
    else
        echo "Error: NVM is not installed correctly. Exiting..."
        exit 1
    fi
}

# Function to install NVM if not found
install_nvm() {
    echo "NVM not found. Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
    load_nvm  # Reload NVM in the current shell
}

# Ensure necessary build tools are available (gcc, make)
install_build_tools() {
    if ! command -v gcc &> /dev/null || ! command -v make &> /dev/null; then
        echo "Installing required build tools..."
        sudo apt update && sudo apt install -y build-essential
    fi
}

# Install Node.js and npm via NVM if not found
install_node_npm() {
    if ! command -v node &> /dev/null; then
        echo "Node.js not found. Installing the latest version using NVM..."
        nvm install node
    fi

    echo "Node.js version: $(node -v)"
    echo "npm version: $(npm -v)"
}

# Add NVM to shell configuration files for future sessions
setup_nvm_for_future_shells() {
    shell_config_files=("$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile")
    for config_file in "${shell_config_files[@]}"; do
        if [ -f "$config_file" ] && ! grep -q "NVM_DIR" "$config_file"; then
            echo "Adding NVM to $config_file..."
            {
                echo 'export NVM_DIR="$HOME/.nvm"'
                echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
                echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'
            } >> "$config_file"
        fi
    done
}

# Source shell config files for the current session
source_shell_files() {
    shell_files=("$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile")
    for shell_file in "${shell_files[@]}"; do
        [ -f "$shell_file" ] && . "$shell_file"
    done
}

# Check if nvm, node, and npm are accessible
check_commands() {
    for cmd in nvm node npm; do
        if ! command -v $cmd &> /dev/null; then
            echo "Error: $cmd is not accessible. Please check the installation."
            exit 1
        fi
    done
    echo "nvm, node, and npm are successfully loaded."
}

# Main logic to handle both root and non-root users
main() {
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        echo "Running as root user."
        NVM_DIR="/root/.nvm"
    else
        echo "Running as non-root user."
    fi

    # Check if NVM is installed, if not install it
    if [ ! -d "$NVM_DIR" ]; then
        install_nvm
    else
        echo "NVM is already installed."
        load_nvm
    fi

    # Ensure build tools are installed
    install_build_tools
    # Install Node.js and npm if not available
    install_node_npm
    # Set up NVM for future shell sessions
    setup_nvm_for_future_shells
    # Source shell files for the current session
    source_shell_files
    # Check if nvm, node, and npm are accessible
    check_commands
    # Debugging output to verify PATH
    echo "Current PATH: $PATH"
    echo "NVM directory: $NVM_DIR"
    echo "Node.js Path: $(command -v node)"
    echo "npm Path: $(command -v npm)"
    echo "NVM, Node.js, and npm setup complete for current and future shells."
}

# Run the main function
main
sleep 10
source ~/.bashrc
