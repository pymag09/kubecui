#!/bin/bash

function node-shell(){
  shell_pod_json="{\"apiVersion\":\"v1\",\"spec\":{\"volumes\":[{\"name\":\"kube-api-access-g5t5g\",\"projected\":{\"sources\":[{\"serviceAccountToken\":{\"expirationSeconds\":3607,\"path\":\"token\"}},{\"configMap\":{\"name\":\"kube-root-ca.crt\",\"items\":[{\"key\":\"ca.crt\",\"path\":\"ca.crt\"}]}},{\"downwardAPI\":{\"items\":[{\"path\":\"namespace\",\"fieldRef\":{\"apiVersion\":\"v1\",\"fieldPath\":\"metadata.namespace\"}}]}}],\"defaultMode\":420}}],\"containers\":[{\"name\":\"shell\",\"image\":\"docker.io/alpine:3.13\",\"command\":[\"nsenter\"],\"args\":[\"-t\",\"1\",\"-m\",\"-u\",\"-i\",\"-n\",\"sleep\",\"14000\"],\"volumeMounts\":[{\"name\":\"kube-api-access-g5t5g\",\"readOnly\":true,\"mountPath\":\"/var/run/secrets/kubernetes.io/serviceaccount\"}],\"terminationMessagePath\":\"/dev/termination-log\",\"terminationMessagePolicy\":\"File\",\"imagePullPolicy\":\"IfNotPresent\",\"securityContext\":{\"privileged\":true}}],\"restartPolicy\":\"Never\",\"terminationGracePeriodSeconds\":0,\"nodeName\":\"NODE_NAME\",\"hostNetwork\":true,\"hostPID\":true,\"hostIPC\":true,\"tolerations\":[{\"operator\":\"Exists\"}],\"priorityClassName\":\"system-node-critical\",\"priority\":2000001000,\"enableServiceLinks\":true,\"preemptionPolicy\":\"PreemptLowerPriority\"}}"
  pod_name_suffix=$(echo $RANDOM | md5sum | head -c 20)
  echo -e "\n\nWait until pod will be scheduled. \nIt might take several seconds.\n\n..."
  kubectl -n kube-system run \
  kube-shell-${pod_name_suffix} \
  --image=alpine:3.13 \
  --overrides=$(echo $shell_pod_json | sed -e "s/NODE_NAME/${1}/") && \
  sleep 5 && \
  kubectl -n kube-system exec -it kube-shell-${pod_name_suffix} -- bash
}

function tcp_port_pair()
{
  pod_port=$(kubectl -n ${1} get pod ${2} -o jsonpath='{.spec.containers[*].ports[?(@.protocol=="TCP")].containerPort}' | tr " " "\n" | sort -r | tail -1)
  echo "Press Ctrl+C to close the session."
  read lower_port upper_port < /proc/sys/net/ipv4/ip_local_port_range
  while :; do
      for (( port = lower_port ; port <= upper_port ; port++ )); do
          kubectl -n ${1} port-forward pods/${2} $port:$pod_port && break 2
      done
  done
}
__logs__(){
  export FZF_DEFAULT_COMMAND="kubectl get pods --all-namespaces"
  fzf --info=inline --layout=reverse --header-lines=1 \
   --prompt "CL: $(kubectl config current-context | sed 's/-context$//') NS: $(kubectl config get-contexts | grep "*" | awk '{print $5}')> " \
   --header $'>> Enter (kubectl exec) || CTRL-L (open log in editor) || CTRL-R (refresh) || CTRL-/ (change view) <<\n\n' \
   --bind 'ctrl-/:change-preview-window(50%,border-bottom|hidden|)' \
   --bind 'enter:execute:kubectl exec -it --namespace {1} {2} -- bash > /dev/tty' \
   --bind 'ctrl-l:execute:${EDITOR:-vim} <(kubectl logs --all-containers --namespace {1} {2}) > /dev/tty' \
   --bind 'ctrl-r:reload:$FZF_DEFAULT_COMMAND' \
   --preview-window up:follow,80%,wrap \
   --preview 'kubectl logs --follow --all-containers --tail=200 --namespace {1} {2}' "$@"
}

__get_obj__(){
  export RS_TYPE=$(echo $1 | base64 -d)
  export FZF_DEFAULT_COMMAND="kubectl get ${RS_TYPE} -n ${NAMESPACE:-default}"
  export FZF_DEFAULT_COMMAND_WIDE="${FZF_DEFAULT_COMMAND} -o wide"
  export -f node-shell
  export -f __explain_obj__
  export -f __prepare_explain__
  PARAMS=()
  case "$RS_TYPE" in
    node?(s) )
        PARAMS+=(--bind 'f2:execute:node-shell {1}')
        HEADER='>> Scrolling: SHIFT - up/down || F1 (descr search) || F2 (shell) || F3 (YAML) || F5 (descr search) || F8 (delete) || CTRL-/ (change view) || CTRL-R (refresh. omit -o wide) || Ctrl-L (-o wide) <<\n\n'
        ;;
    pod?(s) )
        PARAMS+=(--bind 'f2:execute:kubectl exec -it --namespace ${NAMESPACE:-default} {1} -- bash > /dev/tty')
        HEADER='>> Scrolling: SHIFT - up/down || F1 (explain) || F2 (shell) || F3 (YAML) || F4 (edit) || F5 (descr search) || F8 (delete) || CTRL-/ (change view) || CTRL-R (refresh. omit -o wide) || Ctrl-L (-o wide) <<\n\n'
        ;;
    *)
      HEADER='>> Scrolling: SHIFT - up/down || F1 (explain) || F3 (YAML) || F4 (edit) || F5 (descr search) || F8 (delete) || CTRL-/ (change view) || CTRL-R (refresh. omit -o wide) || Ctrl-L (-o wide) <<\n\n'
      ;;
  esac
  fzf --layout=reverse -m --header-lines=1 --info=inline \
    --prompt "[ $RS_TYPE ] CL: $(kubectl config current-context | sed 's/-context$//') NS: $(kubectl config get-contexts | grep "*" | awk '{print $5}')> " \
    --header $"${HEADER}" \
    --preview-window=right:50% \
    --bind 'ctrl-/:change-preview-window(99%|70%|40%|0|50%)' \
    --bind 'ctrl-r:reload:$FZF_DEFAULT_COMMAND' \
    --bind 'ctrl-L:reload:$FZF_DEFAULT_COMMAND_WIDE' \
    --bind 'f1:execute:kubectl -n ${NAMESPACE:-default} describe $RS_TYPE {1} | less' \
    --bind 'f4:execute:kubectl -n ${NAMESPACE:-default} edit $RS_TYPE {1}' \
    --bind 'f8:execute:kubectl delete ${RS_TYPE} {1} --namespace ${NAMESPACE}' \
    --bind 'f1:execute:__explain_obj__ ${RS_TYPE}' \
    --bind 'f3:execute:kubectl -n ${NAMESPACE:-default} get $RS_TYPE {1} -o yaml | less' \
    "${PARAMS[@]}" \
    --bind 'enter:accept' \
    --preview 'kubectl -n ${NAMESPACE:-default} describe $RS_TYPE {1}'
}

__explain__(){
  export FZF_DEFAULT_COMMAND="kubectl api-resources"
  fzf --layout=reverse --header-lines=1 --info=inline \
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
__explain_obj__(){
  export RS_TYPE=$1
  __prepare_explain__ $1 | fzf --layout=reverse --header-lines=1 --info=inline \
    --prompt "CL: $(kubectl config current-context | sed 's/-context$//') NS: $(kubectl config get-contexts | grep "*" | awk '{print $5}')> " \
    --header $'>> Scrolling: SHIFT - up/down || CTRL-/ (change view) Ctrl-f (search word) <<\n\n' \
    --preview-window=right:70% \
    --bind 'ctrl-/:change-preview-window(40%|50%|70%)' \
    --bind 'enter:accept' \
    --bind 'ctrl-f:execute:kubectl explain ${RS_TYPE}.{1} | less' \
    --preview 'kubectl explain ${RS_TYPE}.{1}'
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

__get_obj_all__(){
  export RS_TYPE=$(echo $1 | base64 -d)
  export FZF_DEFAULT_COMMAND="kubectl get $RS_TYPE -A"
  export FZF_DEFAULT_COMMAND_WIDE="${FZF_DEFAULT_COMMAND} -o wide"
  export -f tcp_port_pair
  export -f __explain_obj__
  export -f __prepare_explain__
  PARAMS=()
  case "$RS_TYPE" in
    pod?(s) )
        # PARAMS+=(--bind 'f8:execute:kubectl delete pod {2} --namespace {1}')
        PARAMS+=(--bind 'f6:execute:tcp_port_pair {1} {2}')
        PARAMS+=(--bind 'f2:execute:kubectl exec -it --namespace {1} {2} -- bash > /dev/tty')
        HEADER='>> Scrolling: SHIFT - up/down || F1 (explain) || F3 (YAML) || F4 (edit) || F5 (descr search) || F6 (port-forward) || F8 (delete) || CTRL-/ (change view) || CTRL-R (refresh. omit -o wide) || Ctrl-L (-o wide) <<\n\n'
        ;;
    *)
      HEADER='>> Scrolling: SHIFT - up/down || F1 (explain) || F3 (YAML) || F4 (edit) || F5 (descr search) || F8 (delete) || CTRL-/ (change view) || CTRL-R (refresh. omit -o wide) || Ctrl-L (-o wide) <<\n\n'
      ;;
  esac
  fzf --layout=reverse -m --header-lines=1 --info=inline \
    --prompt "[ $RS_TYPE ] CL: $(kubectl config current-context | sed 's/-context$//') NS: $(kubectl config get-contexts | grep "*" | awk '{print $5}') >" \
    --header $"${HEADER}" \
    --preview-window=right:50% \
    --bind 'ctrl-/:change-preview-window(99%|70%|40%|0|50%)' \
    --bind 'enter:accept' \
    --bind 'f8:execute:kubectl delete ${RS_TYPE} {2} --namespace {1}' \
    --bind 'f4:execute:kubectl edit ${RS_TYPE} {2} --namespace {1}' \
    --bind 'ctrl-r:reload:$FZF_DEFAULT_COMMAND' \
    --bind 'ctrl-L:reload:$FZF_DEFAULT_COMMAND_WIDE' \
    "${PARAMS[@]}" \
    --bind 'f3:execute:kubectl get $RS_TYPE {2} -n {1} -o yaml | less' \
    --bind 'f5:execute:kubectl describe $RS_TYPE {2} -n {1} | less' \
    --bind 'f1:execute:__explain_obj__ ${RS_TYPE}' \
    --preview 'kubectl describe $RS_TYPE {2} -n {1}'
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
    --bind 'enter:accept' \
    --bind 'ctrl-r:reload:$FZF_DEFAULT_COMMAND' \
    --bind 'ctrl-l:reload:$FZF_DEFAULT_COMMAND --sort-by=".lastTimestamp"' \
    --bind 'ctrl-k:reload:$FZF_DEFAULT_COMMAND --sort-by=".firstTimestamp"'
}




k() {
  OBJ=$(echo "$@" | sed -r 's/^.*get[[:space:]](\w+[[:space:]]?[a-z]+[-0-9a-z]*)[[:space:]]?(-n)?.*$/\1/' | base64)
  shopt -s extglob
  case "$@" in
    "config use-context" )  kubectl config use-context $(kubectl config get-contexts | fzf  --layout=reverse --header-lines=1 | sed 's/^\**\s*\([a-z\-]*\).*/\1/');;

    "config set ns" )
            CURRENT_CONTEXT=$(kubectl config current-context)
            kubectl config set contexts.${CURRENT_CONTEXT}.namespace $(kubectl get ns | fzf --layout=reverse --header-lines=1 | sed 's/^\**\s*\([a-z\-]*\).*/\1/');;

    "logs") __logs__;;

    "start") if [[ -n $(which tmuxp) ]]; then
              ${KUI_PATH}/kui_start.sh
             else
              echo "Can not find tmux/tmuxp. Please follow the instructions in the README file to install these tools"
             fi;;

    "explain" ) __explain__;;

    ?( )top?( )@(po)?(d)?(s)?( )+(-A|--all-namespaces) ) __top_all__;;

    ?( )get?( )event?(s)?( )+(-A|--all-namespaces) ) __get_events_all__;;

    explain+( )+([a-z]*) )
            __explain_obj__ $(echo "$@" | sed -r 's/^.*explain[[:space:]](\w+)$/\1/');;

    *-o?( )?(*) ) kubectl "$@";;

    ?( )get?( )+([a-z|.])?( )+(-A|--all-namespaces) )
            __get_obj_all__ $OBJ;;

    ?(-n|--namespace)?([a-z0-9-]*)?( )get?( )events?( )?(-A|--all-namespaces)?(-n|--namespace)?([a-z0-9-]*) )
            kubectl "$@" --sort-by=.lastTimestamp;;

    ?(-n | --namespace)?([a-z0-9-]*)get?( )+([a-z]*)?(-n | --namespace)?([0-9a-z-]*) )
            NS=$(kubectl "$@" -o jsonpath='{.items[*].metadata.namespace}' | sed 's/ /\n/g' | uniq)
            export NAMESPACE=${NS:-$(kubectl "$@" -o jsonpath='{.metadata.namespace}' | sed 's/ /\n/g')}
              __get_obj__ $OBJ
            ;;
    *) kubectl "$@";;
  esac
}
