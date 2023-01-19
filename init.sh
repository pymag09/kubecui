#!/bin/bash

function copy_dm_profile()
{
    if [[ ! -f ~/.tmuxp/$1 ]]; then
            cp ./tmux-profiles/$1.init ~/.tmuxp/$1
            return 0
        else
            echo "~/.tmuxp/$1.yaml already exists"
            return 1
        fi
}

if [[ -z $(grep "source ${response:-$(pwd)}/kubecui.sh" ~/.bashrc) ]]; then
    read -r -p "Add kubecui to .bashrc. [source $(pwd)/kubecui.sh] " response
#
# kubecui.sh creates 'k' alias. Adding it to the .bashrc file to make it work.
#
    echo "source ${response:-$(pwd)}/kubecui.sh" >> ~/.bashrc
fi
read -r -p "Will you use tmux and tmuxp? [y/n] " response
if [[ $response =~ ^([yY])$ ]]; then
    mkdir -p ~/.tmuxp
    read -r -p "Do you want to initialize DARK-SIDE mode? [y/n] " darkside
    if [[ "$darkside" =~ ^([nN])$ ]]; then
#
# NORMAL mode creates one tmux session with 3 windows. Each window corresponds to the environment (dev,stage,prod).
# Settings for the NORMAL mode are stored in the tmux profile file - default.yaml
# All tmux profiles are stored in the $HOME/.tmuxp directory
# If your answer NO, only file default.yaml will be copied to the .tmuxp directory
#
        copy_dm_profile default.yaml
    else
#
# DARK-SIDE mode creates 3 tmux sessions for each environment (dev,stage,prod).
# Settings for the DARK-SIDE mode are stored in the tmux profile, one profile per environament.
# All tmux profiles are stored in the $HOME/.tmuxp directory
# If your answer YES, three files(dev.yaml, stg.yaml, prod.yaml) will bw copied to the .tmuxp directory
#
# DEV
#
        copy_dm_profile dev.yaml
        if [[ $? -eq 0 ]]; then
            read -r -p "kubeconfig for dev environment [~/.kube/dev.yml] " kubecfg
            kubecfg=$(echo $kubecfg | sed 's/\//\\\//g')
            sed -i 's/<KUBECONFIG_PATH>/'"${kubecfg:-~\/.kube\/dev.yml}"'/g' ~/.tmuxp/dev.yaml
        fi
#
# STG
#
        copy_dm_profile stg.yaml
        if [[ $? -eq 0 ]]; then
            read -r -p "kubeconfig for stg environment [~/.kube/stg.yml] " kubecfg
            kubecfg=$(echo $kubecfg | sed 's/\//\\\//g')
            sed -i 's/<KUBECONFIG_PATH>/'"${kubecfg:-~\/.kube\/stg.yml}"'/g' ~/.tmuxp/stg.yaml
        fi
#
# prod
#
        copy_dm_profile prod.yaml
        if [[ $? -eq 0 ]]; then
            read -r -p "kubeconfig for prod environment [~/.kube/prod.yml] " kubecfg
            kubecfg=$(echo $kubecfg | sed 's/\//\\\//g')
            sed -i 's/<KUBECONFIG_PATH>/'"${kubecfg:-~\/.kube\/prod.yml}"'/g' ~/.tmuxp/prod.yaml
        fi
    fi
    if [[ -z $(grep "export KUI_PATH=" ~/.bashrc) ]]; then
        if [[ -z $(grep -E 'export KUI_PATH=.*' ~/.bashrc) ]]; then
            read -r -p "Add \"KUI_PATH\" to .bashrc? [$(pwd)] " response
#
# kui_start.sh activates multi-window, multi-session mode. Regardless of what mode you have chosen, either NORMAL or DARK-SIDE
# you can start it by typeing 'k start' command.
#
            echo "export KUI_PATH=${response:-$(pwd)}" >> ~/.bashrc
            if [[ "$darkside" =~ ^([nN])$ ]]; then
                sed -i 's/#tmuxp load default/tmuxp load default/g' ${response:-$(pwd)}/kui_start.sh
            else
                sed -i 's/#tmuxp load dev stg prod/tmuxp load dev stg prod/g' ${response:-$(pwd)}/kui_start.sh
            fi
        fi
    fi
fi
cat <<EOF
#########################################################
#                                                       #
#  Your ~/.bashrc file has been changed.                #
#  To apply changes - run source ~/.bashrc              #
#  or restart your computer                             #
#                                                       #
#########################################################
EOF
