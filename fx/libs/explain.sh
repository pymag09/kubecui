__prepare_explain__(){
  export RS_TYPE=$1

  EXPLAIN=$(kubectl explain ${RS_TYPE} --recursive | sed -r 's/FIELDS:/---/' | sed -n '\|---|,$p' | sed -r 's/(\w+)(\t|\s)*.*/\1: /g' | yq -o props -P . | sed -r 's/ =//g')

  for line in $EXPLAIN; do
    echo $line
    ST=$line
    for level in $(echo $line | sed -r 's/^([a-zA-Z\.]+)\.(\w+)$/\1/' | sed -r 's/\./ /g'); do
      ST=$(echo $ST | sed -r 's/^([a-zA-Z\.]+)\.(\w+)$/\1/')
      echo $ST
    done
  done | sort | uniq
}

export -f __prepare_explain__

explain_obj(){
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
