# activate hostname fix
if [[ $KUBE_HOSTNAME_FIX = true ]]; then
    export $(kube-hostname-fix enable)
fi
