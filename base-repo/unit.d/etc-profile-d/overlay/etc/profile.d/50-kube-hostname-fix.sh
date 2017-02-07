# activate hostname fix
if [[ $KUBE_HOSTNAME_FIX == true ]]; then
    eval $(kube-hostname-fix enable)
fi
