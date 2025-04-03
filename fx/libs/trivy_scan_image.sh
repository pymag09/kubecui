trivy_scan_image()
{
  which trivy
  if [[ $? == "0" ]]; then
    image=$(kubectl -n ${1} get ${3} ${2} --no-headers -o custom-columns='IMAGE:.spec.template.spec.containers[].image' | tr " " "\n" | fzf --border=double --border-label="╢ Image ╟" --margin 40%)
    echo ${image}
    trivy image -d --severity=CRITICAL,HIGH,MEDIUM ${image} | less
  fi
}
