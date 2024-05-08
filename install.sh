#!/bin/bash

INSTALL_DIR=$HOME/bin

echo "Installing vscode-remote in $INSTALL_DIR"

if [ ! -d "$INSTALL_DIR" ]; then
    mkdir -p $INSTALL_DIR
    echo "  + Created $INSTALL_DIR"
fi

if [[ ! ":$PATH:" == *":$INSTALL_DIR:"* ]]; then

    if [ -f "$HOME/.bashrc" ]; then
        SOURCE=.bashrc
        echo "export PATH=$INSTALL_DIR:\$PATH" >> $HOME/$SOURCE
    elif [ -f "$HOME/.bash_profile" ]; then
        SOURCE=.bash_profile
        echo "export PATH=$INSTALL_DIR:\$PATH" >> $HOME/$SOURCE
    elif [ -f "$HOME/.zshrc" ]; then
        SOURCE=.zshrc
        echo "export PATH=$INSTALL_DIR:\$PATH" >> $HOME/$SOURCE
    else
        echo "  - No .bashrc, .bash_profile or .zshrc found. Please add 'export PATH=$INSTALL_DIR:\$PATH' to your shell configuration file."
        exit 1
    fi

    echo "  + Updated your ~/$SOURCE: added $INSTALL_DIR to PATH"
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cp $SCRIPT_DIR/vscode-remote.sh $INSTALL_DIR/vscode-remote
cp $SCRIPT_DIR/vscode-remote-job.sh $INSTALL_DIR
chmod +x $INSTALL_DIR/vscode-remote

echo "  + vscode-remote installed in $INSTALL_DIR"

if [ ! -z "$SOURCE" ]; then
    echo "Restart your shell or run 'source ~/$SOURCE' to use vscode-remote"
fi