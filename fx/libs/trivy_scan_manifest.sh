trivy_scan_manifest()
{
    which trivy
    if [[ $? == "0" ]]; then
      tmpfile=$(mktemp -u).yaml
      kubectl -n ${1} get ${3}.apps ${2} -o yaml > ${tmpfile}
      trivy config -d --severity=CRITICAL,HIGH,MEDIUM ${tmpfile} | less
    fi
}
