#!/bin/bash

# 第一步：使用 Foundry 的官方安装脚本安装 foundryup
curl -L https://foundry.paradigm.xyz | bash

# 第二步：将 Foundry 二进制文件的路径（forge、cast、anvil）添加到环境变量 PATH 中
if ! grep -q 'export PATH="$HOME/.foundry/bin:$PATH"' ~/.bashrc; then
  echo 'export PATH="$HOME/.foundry/bin:$PATH"' >> ~/.bashrc
fi

if ! grep -q 'export PATH="$HOME/.foundry/bin:$PATH"' ~/.zshrc 2>/dev/null; then
  echo 'export PATH="$HOME/.foundry/bin:$PATH"' >> ~/.zshrc
fi

# 第三步：立即更新 .bashrc 或 .zshrc，以使更改立即生效
if [ "$SHELL" = "/bin/bash" ]; then
  export PATH="$HOME/.foundry/bin:$PATH"  # 使当前 shell 可用
  source ~/.bashrc                        # 为未来的 bash shell 生效
elif [ "$SHELL" = "/bin/zsh" ]; then
  export PATH="$HOME/.foundry/bin:$PATH"  # 使当前 shell 可用
  source ~/.zshrc                         # 为未来的 zsh shell 生效
fi

# 第四步：通过运行 foundryup 验证安装
foundryup

