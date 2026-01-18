#!/bin/bash

# setup-alias.sh
# Run this ONCE on your machine to enable the 'init-ai' shortcut.

SHELL_CONFIG=""
if [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
else
    echo "⚠️  Unknown shell. Please manually add the alias."
    exit 1
fi

ALIAS_CMD="alias init-ai='git init && git submodule add https://github.com/zengtao227/AI-Skills-Hub.git .agent/skills-hub && ./.agent/skills-hub/install.sh && echo \"🤖 AI Brain Injected Successfully!\"'"

if grep -q "alias init-ai" "$SHELL_CONFIG"; then
    echo "✅ Alias 'init-ai' already exists in $SHELL_CONFIG"
else
    echo "" >> "$SHELL_CONFIG"
    echo "# ZengTao AI Skills Hub Shortcut" >> "$SHELL_CONFIG"
    echo "$ALIAS_CMD" >> "$SHELL_CONFIG"
    echo "✅ Alias 'init-ai' added to $SHELL_CONFIG"
    echo "👉 Please run 'source $SHELL_CONFIG' or restart your terminal to use it."
fi
