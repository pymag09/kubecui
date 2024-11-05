tcp_port_pair()
{
  FZF_DEFAULT_OPTS_ORIG=$FZF_DEFAULT_OPTS
  export FZF_DEFAULT_OPTS="--layout=reverse --border=double --border-label=\"╢ Port ╟\" --margin 40%"

  port_number=""
  echo "Press Ctrl+C to close the session."
  read lower_port upper_port < /proc/sys/net/ipv4/ip_local_port_range
  if [[ "${3}" == "service" ]]; then
    port_number=$(kubectl -n ${1} get service ${2} -o jsonpath='{.spec.ports[?(@.protocol=="TCP")].port}' | tr " " "\n" | fzf)
  fi
  if [[ "${3}" == "pod" ]]; then
    port_number=$(kubectl -n ${1} get pod ${2} -o jsonpath='{.spec.containers[*].ports[?(@.protocol=="TCP")].containerPort}' | tr " " "\n" | fzf)
  fi
  while :; do
      for (( port = lower_port ; port <= upper_port ; port++ )); do
        kubectl -n ${1} port-forward ${3}/${2} $port:$port_number && break 2
      done
  done
  export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS_ORIG
}
