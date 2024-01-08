pod_containers()
{
  kubectl -n ${1} get pod ${2} -o jsonpath='{.spec.containers[*].name}' | tr " " "\n" | fzf --border=double --border-label="╢ Container ╟" --margin 40%
}
