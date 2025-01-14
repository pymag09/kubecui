#!/bin/bash

shopt -s extglob

for shotcutfolder in $(find $KUI_PATH/fx/libs -type f -name "*.sh"); do
  source $shotcutfolder
  export -f $(<"$(echo "${shotcutfolder}" | sed 's/\.sh/\.entrypoint/')")
done

__logs__(){
  export FZF_DEFAULT_COMMAND="kubectl get pods --all-namespaces"
  fzf --info=inline --layout=reverse --header-lines=1 \
   --prompt "CL: $(kubectl config current-context | sed 's/-context$//') NS: $(kubectl config get-contexts | grep "*" | awk '{print $5}')> " \
   --header $'>> CTRL-L (open log in editor) || CTRL-R (refresh) || CTRL-/ (change view) <<\n\n' \
   --color ${ENV_FZF_COLOR} \
   --bind 'ctrl-/:change-preview-window(50%|80%)' \
   --bind 'ctrl-l:execute:${EDITOR:-vim} <(kubectl logs --all-containers --namespace {1} {2}) > /dev/tty' \
   --bind 'ctrl-r:reload:$FZF_DEFAULT_COMMAND' \
   --preview-window up:follow,80%,wrap \
   --preview 'kubectl logs --follow --all-containers --tail=200 --namespace {1} {2}' "$@"
}

__explain__(){
  export FZF_DEFAULT_COMMAND="kubectl api-resources"
  fzf --layout=reverse --header-lines=1 --info=inline \
    --prompt "CL: $(kubectl config current-context | sed 's/-context$//') NS: $(kubectl config get-contexts | grep "*" | awk '{print $5}')> " \
    --header $'>> Scrolling: SHIFT - up/down || CTRL-/ (change view) || CTRL-R (refresh. omit -o wide) || Ctrl-L (-o wide) || Ctrl-f (search word) <<\n\n' \
    --preview-window=right:50% \
    --color ${ENV_FZF_COLOR} \
    --bind 'ctrl-/:change-preview-window(70%|40%|50%)' \
    --bind 'enter:accept' \
    --bind 'ctrl-r:reload:$FZF_DEFAULT_COMMAND' \
    --bind 'ctrl-L:reload:$FZF_DEFAULT_COMMAND_WIDE' \
    --bind 'ctrl-f:execute:kubectl describe $RS_TYPE {2} -n {1} | less' \
    --preview 'kubectl explain {1}'
}

__get_obj__(){
  RS_TYPE=$(echo $1 | base64 -d)
  export FZF_DEFAULT_COMMAND_WIDE="${FZF_DEFAULT_COMMAND} -o wide"
  source "$KUI_PATH"/fx/default/config
  if [[ -f "$KUI_PATH"/fx/"${RS_TYPE}"/config ]]; then
    source "$KUI_PATH"/fx/"${RS_TYPE}"/config
  fi

  fzf --layout=reverse -m --header-lines=1 --info=inline \
    --prompt "[ $RS_TYPE ] CL: $(kubectl config current-context | sed 's/-context$//') NS: $(kubectl config get-contexts | grep "*" | awk '{print $5}')> " \
    --header $"${HEADER}" \
    --color ${ENV_FZF_COLOR} \
    --preview-window=right:50% \
    --bind 'ctrl-/:change-preview-window(99%|70%|40%|0|50%)' \
    --bind 'ctrl-r:reload:$FZF_DEFAULT_COMMAND' \
    --bind 'ctrl-L:reload:$FZF_DEFAULT_COMMAND_WIDE' \
    "${PARAMS[@]}" \
    --bind 'enter:accept' \
    --preview "kubectl describe $RS_TYPE {1}"
}

__get_obj_all__(){
  RS_TYPE=$(echo $1 | base64 -d)
  export FZF_DEFAULT_COMMAND_WIDE="${FZF_DEFAULT_COMMAND} -o wide"
  source "$KUI_PATH"/fx/default/config
  if [[ -f "$KUI_PATH"/fx/"${RS_TYPE}"/config ]]; then
    source "$KUI_PATH"/fx/"${RS_TYPE}"/config
  fi

  fzf --layout=reverse -m --header-lines=1 --info=inline \
    --prompt "[ $RS_TYPE ] CL: $(kubectl config current-context | sed 's/-context$//') NS: $(kubectl config get-contexts | grep "*" | awk '{print $5}') >" \
    --header $"${HEADER}" \
    --color ${ENV_FZF_COLOR} \
    --preview-window 'right,50%' \
    --bind 'ctrl-/:change-preview-window(99%|70%|40%|0|50%)' \
    --bind 'enter:accept' \
    --bind 'ctrl-r:reload:$FZF_DEFAULT_COMMAND' \
    --bind 'ctrl-L:reload:$FZF_DEFAULT_COMMAND_WIDE' \
    "${PARAMS[@]}" \
    --preview "kubectl describe $RS_TYPE {2} -n {1}"
}

__top_all__(){
  export FZF_DEFAULT_COMMAND="kubectl top pod -A --no-headers"
  fzf --info=inline --layout=reverse \
    --prompt "CL: $(kubectl config current-context | sed 's/-context$//') NS: $(kubectl config get-contexts | grep "*" | awk '{print $5}')> " \
    --header $'>> Sort by .. Ctrl + u: CPU || Ctrl + m: MEM  <<\n\n' \
    --preview-window=right:50% \
    --bind 'ctrl-/:change-preview-window(70%|40%|50%)' \
    --bind 'enter:accept' \
    --bind 'ctrl-u:reload:$FZF_DEFAULT_COMMAND | sort -k 3 -h -r' \
    --bind 'ctrl-m:reload:$FZF_DEFAULT_COMMAND | sort -k 4 -h -r' \
    --preview 'kubectl describe pod {2} -n {1}'
}

__get_events_all__(){
  export FZF_DEFAULT_COMMAND="kubectl get event --all-namespaces"
  fzf --info=inline --header-lines=1 --layout=reverse \
    --prompt "CL: $(kubectl config current-context | sed 's/-context$//') NS: $(kubectl config get-contexts | grep "*" | awk '{print $5}')> " \
    --header $'>> Ctrl+r: Reload || Sort by .. Ctrl + k: first time || Ctrl + l: last time  <<\n\n' \
    --color ${ENV_FZF_COLOR} \
    --bind 'enter:accept' \
    --bind 'ctrl-r:reload:$FZF_DEFAULT_COMMAND' \
    --bind 'ctrl-l:reload:$FZF_DEFAULT_COMMAND --sort-by=".lastTimestamp"' \
    --bind 'ctrl-k:reload:$FZF_DEFAULT_COMMAND --sort-by=".firstTimestamp"'
}

__normalize_resource_data() {
    local word="$1"

    if [[ $word =~ \. ]]; then
      echo "$word"
      return 0
    fi
    while read -r plural short _; do
        if [ "$word" == "$plural" ] || [ "$word" == "$short" ] || [ "$word" == "$(echo "$plural" | sed -r 's/s$//')" ] || [ "$word" == "$(echo "$plural" | sed -r 's/e?s$//')" ]; then
            echo "$plural"
            break
        fi
    done < <(kubectl api-resources --no-headers | awk '{print $1, $2}' | awk '{if (NF == 1) $2 = $1; print}' | sort -r)
}

k() {
  OBJ=$(__normalize_resource_data $(echo "$@" | sed -E 's/^.*get[[:space:]]([[:alnum:]]+[[:space:]]?[[:lower:]]+[-0-9.[:lower:]]*)[[:space:]]?(-)?.*$/\1/'))
  case "$@" in
    "config use-context" )  kubectl config use-context $(kubectl config get-contexts | fzf  --layout=reverse --header-lines=1 | sed 's/^\**\s*\([A-Z0-9a-z\-]*\).*/\1/');;

    "config set ns" )
            CURRENT_CONTEXT=$(kubectl config current-context)
            kubectl config set contexts.${CURRENT_CONTEXT}.namespace $(kubectl get ns | fzf --layout=reverse --header-lines=1 | sed 's/^\**\s*\([A-Z0-9a-z\-]*\).*/\1/');;

    "logs") __logs__;;
    "stop") tmux kill-session -a
            tmux kill-session;;
    "start") if [[ -n $(which tmuxp) ]]; then
              ${KUI_PATH}/kui_start.sh
             else
              echo "Can not find tmux/tmuxp. Please follow the instructions in the README file to install these tools"
             fi;;

    "explain" ) __explain__;;

    ?( )top?( )@(po)?(d)?(s)?( )+(-A|--all-namespaces) ) __top_all__;;

    ?( )get?( )event?(s)?( )+(-A|--all-namespaces) ) __get_events_all__;;

    explain+( )+([a-z]*) )
            explain_obj $(echo "$@" | sed -r 's/^.*explain[[:space:]]([[:lower:]]+)$/\1/');;

    *-o?( )?(*) ) kubectl "$@";;

    ?(-n|--namespace)?([a-z0-9-]*)?( )get?( )events?( )?(-A|--all-namespaces)?(-n|--namespace)?([a-z0-9-]*) )
            kubectl "$@" --sort-by=.lastTimestamp;;

    ?( )get?( )+([a-z|.])?( )+(-A|--all-namespaces) )
            export FZF_DEFAULT_COMMAND="kubectl get $OBJ -A"
            export SCOPED=$(kubectl api-resources --no-headers --namespaced | grep -E "^$(echo $OBJ | sed -r "s/^([a-zA-Z]+).*/\1/")" | wc -l | tr -d '0' | sed -r 's/[0-9]+/ /')
            export NONSCOPED=$SCOPED
            if [[ "${SCOPED}" == " " ]]; then
              __get_obj_all__ $(echo $OBJ | base64)
            else
              __get_obj__ $(echo $OBJ | base64)
            fi
            ;;

    ?(-n | --namespace)?([a-z0-9-]*)get?( )+([a-z]*)?(-n | --namespace)?([0-9a-z-]*) )
            export SCOPED=$(kubectl api-resources --no-headers --namespaced | grep -E "^$(echo $OBJ | sed -r "s/^([a-zA-Z]+).*/\1/")" | wc -l | tr -d '0' | sed -r 's/[0-9]+/ /')
            export NONSCOPED=$SCOPED
            if [[ "${SCOPED}" == " " ]]; then
              NS=$(kubectl "$@" -o jsonpath='{.items[*].metadata.namespace}' | sed 's/ /\n/g' | uniq)
              NAMESPACE=${NS:-$(kubectl "$@" -o jsonpath='{.metadata.namespace}' | sed 's/ /\n/g')}
              export FZF_DEFAULT_COMMAND="kubectl get $OBJ -A --field-selector metadata.namespace=${NAMESPACE}"
              __get_obj_all__ $(echo $OBJ | base64)
            else
              export FZF_DEFAULT_COMMAND="kubectl get $OBJ"
              unset SCOPED
              unset NONSCOPED
              __get_obj__ $(echo $OBJ | base64)
            fi
            ;;
    *) kubectl "$@";;
  esac
}
