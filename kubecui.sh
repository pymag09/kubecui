#!/bin/bash

__logs__(){
  export FZF_DEFAULT_COMMAND="kubectl get pods --all-namespaces"
  fzf --info=inline --layout=reverse --header-lines=1 \
   --prompt "CL: $(kubectl config current-context | sed 's/-context$//') NS: $(kubectl config get-contexts | grep "*" | awk '{print $5}')> " \
   --header $'>> Enter (kubectl exec) || CTRL-L (open log in editor) || CTRL-R (refresh) || CTRL-/ (change view) <<\n\n' \
   --bind 'ctrl-/:change-preview-window(50%,border-bottom|hidden|)' \
   --bind 'enter:execute:kubectl exec -it --namespace {1} {2} -- bash > /dev/tty' \
   --bind 'ctrl-l:execute:${EDITOR:-vim} <(kubectl logs --all-containers --namespace {1} {2}) > /dev/tty' \
   --bind 'ctrl-r:reload:$FZF_DEFAULT_COMMAND' \
   --preview-window up:follow,80% \
   --preview 'kubectl logs --follow --all-containers --tail=200 --namespace {1} {2}' "$@"
}

__get_obj__(){
  export RS_TYPE=$(echo $1 | base64 -d)
  export FZF_DEFAULT_COMMAND="kubectl get ${RS_TYPE} -n ${NAMESPACE:-default}"
  export FZF_DEFAULT_COMMAND_WIDE="${FZF_DEFAULT_COMMAND} -o wide"
  fzf --header-lines=1 --info=inline \
    --prompt "CL: $(kubectl config current-context | sed 's/-context$//') NS: $(kubectl config get-contexts | grep "*" | awk '{print $5}')> " \
    --header $'>> Scrolling: SHIFT - up/down || CTRL-/ (change view) || CTRL-R (refresh. omit -o wide) || Ctrl-L (-o wide) || Ctrl-f (search word) <<\n\n' \
    --preview-window=right:50% \
    --bind 'ctrl-/:change-preview-window(70%|40%|50%)' \
    --bind 'ctrl-r:reload:$FZF_DEFAULT_COMMAND' \
    --bind 'ctrl-L:reload:$FZF_DEFAULT_COMMAND_WIDE' \
    --bind 'ctrl-f:execute:kubectl -n ${NAMESPACE:-default} describe $RS_TYPE {1} | less' \
    --bind 'enter:accept' \
    --preview 'kubectl -n ${NAMESPACE:-default} describe $RS_TYPE {1}'
}

__get_obj_all__(){
  export RS_TYPE=$(echo $1 | base64 -d)
  export FZF_DEFAULT_COMMAND="kubectl get $RS_TYPE -A"
  export FZF_DEFAULT_COMMAND_WIDE="${FZF_DEFAULT_COMMAND} -o wide"
  fzf --header-lines=1 --info=inline \
    --prompt "CL: $(kubectl config current-context | sed 's/-context$//') NS: $(kubectl config get-contexts | grep "*" | awk '{print $5}')> " \
    --header $'>> Scrolling: SHIFT - up/down || CTRL-/ (change view) || CTRL-R (refresh. omit -o wide) || Ctrl-L (-o wide) || Ctrl-f (search word) <<\n\n' \
    --preview-window=right:50% \
    --bind 'ctrl-/:change-preview-window(70%|40%|50%)' \
    --bind 'enter:accept' \
    --bind 'ctrl-r:reload:$FZF_DEFAULT_COMMAND' \
    --bind 'ctrl-L:reload:$FZF_DEFAULT_COMMAND_WIDE' \
    --bind 'ctrl-f:execute:kubectl describe $RS_TYPE {2} -n {1} | less' \
    --preview 'kubectl describe $RS_TYPE {2} -n {1}'
}

__explain__(){
  export FZF_DEFAULT_COMMAND="kubectl api-resources"
  fzf --header-lines=1 --info=inline \
    --prompt "CL: $(kubectl config current-context | sed 's/-context$//') NS: $(kubectl config get-contexts | grep "*" | awk '{print $5}')> " \
    --header $'>> Scrolling: SHIFT - up/down || CTRL-/ (change view) || CTRL-R (refresh. omit -o wide) || Ctrl-L (-o wide) || Ctrl-f (search word) <<\n\n' \
    --preview-window=right:50% \
    --bind 'ctrl-/:change-preview-window(70%|40%|50%)' \
    --bind 'enter:accept' \
    --bind 'ctrl-r:reload:$FZF_DEFAULT_COMMAND' \
    --bind 'ctrl-L:reload:$FZF_DEFAULT_COMMAND_WIDE' \
    --bind 'ctrl-f:execute:kubectl describe $RS_TYPE {2} -n {1} | less' \
    --preview 'kubectl explain {1}'
}

__prepare_explain__(){
  export RS_TYPE=$1

  EXPLAIN=$(kubectl explain ${RS_TYPE} --recursive | sed -r 's/FIELDS:/---/' | sed -n '\|---|,$p' | sed -r 's/(\w+)\t.*/\1:/g' | yq -o props -P . | sed -r 's/ =//g')

  for line in $EXPLAIN; do
    echo $line
    ST=$line
    for level in $(echo $line | sed -r 's/^([a-zA-Z\.]+)\.(\w+)$/\1/' | sed -r 's/\./ /g'); do
      ST=$(echo $ST | sed -r 's/^([a-zA-Z\.]+)\.(\w+)$/\1/')
      echo $ST
    done
  done | sort | uniq
}

__explain_obj__(){
  export RS_TYPE=$1
  __prepare_explain__ $1 | fzf --header-lines=1 --info=inline \
    --prompt "CL: $(kubectl config current-context | sed 's/-context$//') NS: $(kubectl config get-contexts | grep "*" | awk '{print $5}')> " \
    --header $'>> Scrolling: SHIFT - up/down || CTRL-/ (change view) Ctrl-f (search word) <<\n\n' \
    --preview-window=right:70% \
    --bind 'ctrl-/:change-preview-window(40%|50%|70%)' \
    --bind 'enter:accept' \
    --bind 'ctrl-f:execute:kubectl explain ${RS_TYPE}.{1} | less' \
    --preview 'kubectl explain ${RS_TYPE}.{1}'
}

k() {
  OBJ=$(echo $@ | sed -r 's/^.*get[[:space:]](\w+[[:space:]]?[a-z]+[-0-9a-z]*)[[:space:]]?(-n)?.*$/\1/' | base64)
  shopt -s extglob
  case "$@" in
    "config use-context" )  kubectl config use-context $(kubectl config get-contexts | fzf  --header-lines=1 | sed 's/^\**\s*\([a-z\-]*\).*/\1/');;

    "config set ns" )
            CURRENT_CONTEXT=$(kubectl config current-context)
            kubectl config set contexts.${CURRENT_CONTEXT}.namespace $(kubectl get ns | fzf --header-lines=1 | sed 's/^\**\s*\([a-z\-]*\).*/\1/');;

    "logs") __logs__;;

    "explain" ) __explain__;;

    explain+( )+([a-z]*) )
            __explain_obj__ $(echo $@ | sed -r 's/^.*explain[[:space:]](\w+)$/\1/');;

    *-o?( )?(*) ) kubectl $@;;

    ?( )get?( )+([a-z|.])?( )+(-A|--all-namespaces) )
            __get_obj_all__ $OBJ;;

    ?(-n|--namespace)?([a-z0-9-]*)?( )get?( )events?( )?(-A|--all-namespaces)?(-n|--namespace)?([a-z0-9-]*) )
            kubectl $@ --sort-by=.lastTimestamp;;

    ?(-n | --namespace)?([a-z0-9-]*)get?( )+([a-z]*)?(-n | --namespace)?([0-9a-z-]*) )
            NS=$(kubectl $@ -o jsonpath='{.items[*].metadata.namespace}' | sed 's/ /\n/g' | uniq)
            export NAMESPACE=${NS:-$(kubectl $@ -o jsonpath='{.metadata.namespace}' | sed 's/ /\n/g')}
              __get_obj__ $OBJ
            ;;
    *) kubectl $@;;
  esac
}
