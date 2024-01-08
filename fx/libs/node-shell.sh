node-shell(){
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
