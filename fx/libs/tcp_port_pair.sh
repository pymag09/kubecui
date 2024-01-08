tcp_port_pair()
{
  pod_port=$(kubectl -n ${1} get pod ${2} -o jsonpath='{.spec.containers[*].ports[?(@.protocol=="TCP")].containerPort}' | tr " " "\n" | fzf --border=double --border-label="╢ Port ╟" --margin 40%)
  echo "Press Ctrl+C to close the session."
  read lower_port upper_port < /proc/sys/net/ipv4/ip_local_port_range
  while :; do
      for (( port = lower_port ; port <= upper_port ; port++ )); do
          kubectl -n ${1} port-forward pods/${2} $port:$pod_port && break 2
      done
  done
}
