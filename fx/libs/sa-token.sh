create_sa_token()
{
  kubectl create secret docker-registry ${2} -n ${1} --from-file /dev/null --dry-run=client -o yaml | \
  sed -r 's/^type:.*$/type\: kubernetes\.io\/service-account-token/' | \
  sed -r "s/creationTimestamp.*/annotations:\n    kubernetes.io\/service-account.name: ${2}/" | \
  sed 's/"null": ""//' | \
  kubectl apply -f -
}
