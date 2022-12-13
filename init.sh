#!/bin/bash

if [[ -z $(grep "source ${response:-$(pwd)}/kubecui.sh" ~/.bashrc) ]]; then
    read -r -p "Add kubecui to .bashrc. [source $(pwd)/kubecui.sh] " response
    echo "source ${response:-$(pwd)}/kubecui.sh" >> ~/.bashrc
fi
read -r -p "Will you use tmux and tmuxp? [y/n] " response
if [[ "$response" =~ ^([yY])$ ]]; then
    mkdir -p ~/.tmuxp
    if [[ ! -f ~/.tmuxp/default.yaml ]]; then
        cp ./default.yaml.init ~/.tmuxp/default.yaml
    else
        echo "~/.tmuxp/default.yaml already exists"
    fi
    if [[ -z $(grep "export KUI_PATH=" ~/.bashrc) ]]; then
        if [[ -z $(grep -E 'export KUI_PATH=.*' ~/.bashrc) ]]; then
            read -r -p "Add \"KUI_PATH\" to .bashrc? [$(pwd)] " response
            echo "export KUI_PATH=${response:-$(pwd)}" >> ~/.bashrc
        fi
    fi
fi
