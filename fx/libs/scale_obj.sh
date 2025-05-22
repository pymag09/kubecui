scale_obj ()
{
    kubectl --namespace ${2} scale ${1} ${3} --replicas=$(seq 0 100 | fzf)
}
