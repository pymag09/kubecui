secret_base64_decode()
{
  echo '' | fzf --border=double --preview-window=top,99%,wrap --border-label="╢ Base64 decoded ╟" --preview="kubectl get secret ${1}  --namespace ${2} -o jsonpath='{.data}' | jq 'walk(if type == \"string\" then @base64d else . end)'"
}
