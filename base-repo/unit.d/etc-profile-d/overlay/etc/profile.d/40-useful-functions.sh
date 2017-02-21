# USEFUL FUNCTIONS

# public unscoped functions

function clear {
    echo -ne '\0033\0143'
}

function _get-container-id {
    basename "$(cat /proc/1/cgroup | grep docker | head -1)"
}

function container-id {
    local cid
    case "$1" in
        s|short)
            _get-container-id | cut -c 1-12
            ;;
        f|full|l|long)
            _get-container-id
            ;;
        h|help)
            echo "Usage $0 {short|full|help}"
            return 1
            ;;
        *)
            container-id short
            ;;
    esac
}

function get-ipv4 {
    local interface="${1:-eth0}"
    if linux::cmd::exists 'ip'; then
        ip -o -f inet addr show $interface | sed 's/.*inet \(.*\)\/.*/\1/'
    elif linux::cmd::exists 'ifconfig'; then
        ifconfig $interface | grep 'inet ' | cut -d':' -f2 | awk '{print $1}'
    elif linux::cmd::exists 'hostname'; then
        hostname -i | head -1
    fi
}


# logging functions

function log::get-time {
    date '+%Y-%m-%d %H:%M:%S'
}

function log::_show-msg {
    local symbol_map
    declare -A symbol_map=(
        [info]='*'
        [warn]='-'
        [error]='x'
    )
    local color_map
    declare -A color_map=(
        [info]='36'
        [warn]='33'
        [error]='31'
    )
    local msg="$1"
    local type="${2:-info}"
    local symbol="${symbol_map[$type]}"
    local color="${color_map[$type]}"
    local time="$(log::get-time) "
    if [[ ! $(basename "$0") = 'bash' && ! -z $(basename "$0") ]]; then
        local module="[${3:-$(basename $0)}] "
    fi
    type+=' '
    if [ ! -z "$minimal" ]; then
        unset time type
    fi
    echo -e "\E[${color}m[${symbol}]\E[0m ${time}${type^^}${module}${msg}" >&2
}

function log::info {
    local msg="$@"
    log::_show-msg "$msg" 'info'
}

function log::error {
    local msg="$@"
    log::_show-msg "$msg" 'error'
}

function log::warn {
    local msg="$@"
    log::_show-msg "$msg" 'warn'
}

function log::m-info {
    local msg="$@"
    local minimal=true
    log::info "$msg"
}

function log::m-warn {
    local msg="$@"
    local minimal=true
    log::warn "$msg"
}

function log::m-error {
    local msg="$@"
    local minimal=true
    log::error "$msg"
}

# linux functions

function linux::cmd::exists {
    local cmd="$1"
    hash "$cmd" > /dev/null 2>&1
}

function linux::cmd::does-not-exist {
    local cmd="$1"
    hash "$cmd" > /dev/null 2>&1
}

function linux::cap::is-enabled {
    local name="$1"
    capsh --print | grep -q cap_${name,,}
}

function linux::cap::is-disabled {
    ! linux::cap::is-enabled "$1"
}

function linux::cap::show-warning {
    local name="$1"
    if [[ ! $(basename "$0") = 'bash' && ! -z $(basename "$0") ]]; then
        local _module="[${3:-$(basename $0)}] "
        local _len=${#_module}
        # ((_len+=2))
        local _space=$(printf ' %.0s' $(seq 1 $_len))
    fi
    log::m-warn "The cap CAP_${name^^} is restricted in this container.
    ${_space}It's recommended to run this container with --cap-add ${name^^}"
}

function linux::get-shell-vars {
    local names_only="${1:-false}"
    local _res=$(compgen -v | grep -v ^names_only)
    local _var
    if [[ ! $names_only = true ]]; then
        _res=$(echo "$_res" | while read _var; do printf "%s=%q\n" "$_var" "${!_var}"; done)
    fi
    printf '%s\n' "$_res"
}

function linux::get-shell-var-names {
    linux::get-shell-vars true
}

function linux::get-env-vars {
    local names_only="${1:-false}"
    local _res=$(env | grep -v ^names_only)
    if [[ $names_only = true ]]; then
        _res=$(echo "$_res" | cut -d'=' -f1)
    fi
    printf '%s\n' "$_res"
}

function linux::get-env-var-names {
    linux::get-env-vars true
}

function linux::get-function-names {
    compgen -A function
}

# net functions

function net::is-long-hostname {
    [[ $USE_LONG_HOSTNAME == true || $(hostname) =~ \. ]]
}

function net::is-short-hostname {
    ! base::is-long-hostname
}

function net::get-mtu {
    local interface="${1:-eth0}"
    if linux::cmd::exists 'ip'; then
        ip -o link show $interface | awk '{print $5}'
    elif linux::cmd::exists 'ifconfig'; then
        ifconfig $interface | grep MTU | awk '{print $5}' | cut -d':' -f2
    fi
}

# kubernetes functions

function kube::is-kubernetes {
    [ ! -z "${KUBERNETES_SERVICE_HOST+x}" ]
}

function kube::dns::get-cluster-domain {
    dig +short +search -t SRV kubernetes | head -1 | cut -d'.' -f5-6
}

function kube::sd::get-port {
    local name="$1"
    local protocol="${2:-tcp}"
    local service="${3:-$(kube::host::get-service)}"
    dig +short +search _${name,,}._${protocol,,}.${service} -t SRV | head -1 | awk '{print $3}'
}

function kube::sd::get-hosts {
    local service="${1:-$(kube::host::get-service)}"
    dig +short +search -t SRV "$service" | awk '{print $4}' | sed 's/\.$//g' | sort
}

function kube::sd::num-hosts {
    local service="${1:-$(kube::host::get-service)}"
    kube::sd::get-hosts "$service" | wc -w
}

function kube::api::endpoint::_parse-ips {
    while read -r line; do
        echo "$line" | jq -r ".subsets[] | .addresses[] | .ip" 2> /dev/null
    done
}

# function kube::api::endpoint::_parse-hosts {
#     while read -r line; do
#         echo "$line" | kube::api::endpoint::_parse-ips | kube::api::pod::ip-to-hostname
#     done
# }

function kube::api::endpoint::_parse-nodes {
    while read -r line; do
        echo "$line" | jq -r ".subsets[] | .addresses[] | .nodeName" 2> /dev/null
    done
}

function kube::api::endpoint::_parse-ports {
    while read -r line; do
        echo "$line" | jq -r ".subsets[] | .ports[] | .port" 2> /dev/null
    done
}

function kube::api::pod::ip-to-hostname {
    local namespace="${1:-$(kube::sa::get-namespace)}"
    local domain=$(kube::resolv::get-domain)
    while read -r line; do
        local ip=$(echo "$line" | sed 's/\./-/g')
        echo "${ip}.${namespace}.pod.${domain}"
    done
}

function kube::api::endpoint::get-hosts {
    local query="$1"
    kube::api::endpoint::get "$query" | kube::api::endpoint::_parse-ips | kube::api::pod::ip-to-hostname
}

function kube::api::endpoint::get-ips {
    local query="$1"
    kube::api::endpoint::get "$query" | kube::api::endpoint::_parse-ips
}

function kube::api::endpoint::get-nodes {
    local query="$1"
    kube::api::endpoint::get "$query" | kube::api::endpoint::_parse-nodes
}

function kube::api::endpoint::get-ports {
    local query="$1"
    kube::api::endpoint::get "$query" | kube::api::endpoint::_parse-ports
}

function kube::api::endpoint::get-port {
    local query="$1"
    local portname="$2"
    kube::api::endpoint::get "$query" | jq -e -r ".subsets[] | .ports[] | select(.name == \"${portname}\") | .port"
}

function kube::api::service::get {
    local query="$1"
    local type=$(echo "$FUNCNAME" | cut -d':' -f5)
    kube::api::_get-object $type "$query"
}

function kube::api::endpoint::get {
    local query="$1"
    local type=$(echo "$FUNCNAME" | cut -d':' -f5)
    kube::api::_get-object $type "$query"
}

function kube::api::pod::get {
    local query="$1"
    local type=$(echo "$FUNCNAME" | cut -d':' -f5)
    kube::api::_get-object $type "$query"
}

function kube::api::statefulset::get {
    local query="$1"
    local type=$(echo "$FUNCNAME" | cut -d':' -f5)
    kube::api::_get-object $type "$query"
}

function kube::api::deployment::get {
    local query="$1"
    local type=$(echo "$FUNCNAME" | cut -d':' -f5)
    kube::api::_get-object $type "$query"
}

function kube::api::replicaset::get {
    local query="$1"
    local type=$(echo "$FUNCNAME" | cut -d':' -f5)
    kube::api::_get-object $type "$query"
}

function kube::api::daemonset::get {
    local query="$1"
    local type=$(echo "$FUNCNAME" | cut -d':' -f5)
    kube::api::_get-object $type "$query"
}

function kube::api::configmap::get {
    local query="$1"
    local type=$(echo "$FUNCNAME" | cut -d':' -f5)
    kube::api::_get-object $type "$query"
}

function kube::api::secret::get {
    local query="$1"
    local type=$(echo "$FUNCNAME" | cut -d':' -f5)
    kube::api::_get-object $type "$query"
}

function kube::api::namespace::get {
    local query="$1"
    local type=$(echo "$FUNCNAME" | cut -d':' -f5)
    kube::api::_get-object $type "$query"
}

function kube::api::ingress::get {
    local query="$1"
    local type=$(echo "$FUNCNAME" | cut -d':' -f5)
    kube::api::_get-object $type "$query"
}

function kube::api::node::get {
    local query="$1"
    local type=$(echo "$FUNCNAME" | cut -d':' -f5)
    kube::api::_get-object $type "$query"
}

function kube::api::pv::get {
    local query="$1"
    local type=$(echo "$FUNCNAME" | cut -d':' -f5)
    kube::api::_get-object $type "$query"
}

function kube::api::pvc::get {
    local query="$1"
    local type=$(echo "$FUNCNAME" | cut -d':' -f5)
    kube::api::_get-object $type "$query"
}

function kube::api::job::get {
    local query="$1"
    local type=$(echo "$FUNCNAME" | cut -d':' -f5)
    kube::api::_get-object $type "$query"
}

function kube::api::event::get {
    local query="$1"
    local type=$(echo "$FUNCNAME" | cut -d':' -f5)
    kube::api::_get-object $type "$query"
}

function kube::api::networkpolicy::get {
    local query="$1"
    local type=$(echo "$FUNCNAME" | cut -d':' -f5)
    kube::api::_get-object $type "$query"
}

function kube::api::is-namespaced {
    local type="$1"
    local not_namespaced=(namespace node pv)
    echo "${not_namespaced[@]}" | grep -v -q $type
}

function kube::api::is-not-namespaced {
    local query="$1"
    ! kube::api::is-namespaced "$query"
}

function kube::api::_build-uri {
    local type="$1"
    local name="$2"
    local api=$(kube::api::_get-api $type)
    local endpoint=$(kube::api::_get-endpoint $type)
    uri=https://kubernetes
    uri+="/$api"
    if kube::api::is-namespaced $type; then
        local namespace=$(kube::sa::get-namespace)
        uri+="/namespaces/$namespace"
    fi
    uri+="/$endpoint"
    if [ ! -z $name ]; then
        uri+="/$name"
    fi
    echo "$uri"
}

function kube::api::_get-endpoint {
    local type="$1"
    local uri_map
    declare -A uri_map=(
        [ingress]='ingresses'
        [pv]='persistentvolumes'
        [pvc]='persistentvolumeclaims'
        [hpa]='horizontalpodautoscalers'
        [networkpolicy]='networkpolicies')

    case "$type" in
        endpoint|service|pod|statefulset|deployment|replicaset|daemonset|configmap|secret|namespace|node|job|event)
            echo "${type}s"
            ;;
        ingress|pv|pvc|hpa|networkpolicy)
            echo "${uri_map[$type]}"
            ;;
    esac
}

function kube::api::_get-api {
    local type="$1"
    case "$type" in
        endpoint|service|pod|configmap|secret|namespace|node|pv|pvc|event)
            echo 'api/v1'
            ;;
        deployment|replicaset|daemonset|ingress|networkpolicy)
            echo 'apis/extensions/v1beta1'
            ;;
        statefulset)
            echo 'apis/apps/v1beta1'
            ;;
        job)
            echo 'apis/batch/v1'
            ;;
    esac
}

function kube::api::_get-object {
    local type="$1"
    local name="$2"
    local token=$(kube::sa::get-token)
    local uri=$(kube::api::_build-uri $type $name)
    local req=$(curl -sSL -k -H "Authorization: Bearer $token" "$uri" 2> /dev/null)
    if [[ $(echo "$req" | jq -r '.status') = 'Failure' ]]; then
        return 1
    else
        echo "$req" | jq -c -M -e '.'
        return 0
    fi
}


function kube::sa::_get-path {
    local query="$1"
    local base='/var/run/secrets/kubernetes.io/serviceaccount'
    local paths
    declare -A paths=(
        [namespace]="$base/namespace"
        [token]="$base/token"
        [ca]="$base/ca.crt"
    )
    echo "${paths[$query]}"
}

function kube::sa::get-namespace {
    local path=$(kube::sa::_get-path 'namespace')
    cat "$path"
}

function kube::sa::get-token {
    local path=$(kube::sa::_get-path 'token')
    cat "$path"
}

function kube::host::_parse {
    local host=$(hostname -f)
    echo "${host//\./ }"
}

function kube::resolv::get-domain {
    cat /etc/resolv.conf | grep ^search | head -1 | sed 's/.*\.svc\.\(.*\)\ svc.*/\1/'
}

function kube::host::is-statefulset {
    local parts=($(kube::host::_parse))
    local tip=${parts[0]}
    tip=(${tip//\-/ })
    [[ ${#parts[@]} = 6 && ${#tip[@]} = 2 && ${parts[-3]} = 'svc' ]]
}

function kube::host::isnt-statefulset {
    ! kube::host::is-statefulset
}

function kube::host::get-domain {
    local parts=($(kube::host::_parse))
    echo "${parts[-2]}.${parts[-1]}"
}

function kube::host::get-namespace {
    local parts=($(kube::host::_parse))
    echo "${parts[-4]}"
}

function kube::host::get-service {
    local parts=($(kube::host::_parse))
    echo "${parts[-5]}"
}

function kube::host::get-node {
    local parts=($(kube::host::_parse))
    echo "${parts[0]}"
}

function kube::host::_parse-node {
    local node=$(kube::host::get-node)
    echo "${node//\-/ }"
}

function kube::host::get-statefulset {
    if kube::host::is-statefulset; then
        local node=($(kube::host::_parse-node))
        echo "${node[0]}"
    fi
}

function kube::host::get-index {
    if kube::host::is-statefulset; then
        local node=($(kube::host::_parse-node))
        echo "${node[1]}"
    fi
}

function kube::host::is-master {
    [[ $(kube::host::get-index) = 0 ]]
}

function kube::host::get-hostname {
    local parts=($(kube::host::_parse))
    if kube::host::isnt-statefulset && [[ ${#parts[@]} = 6 ]]; then
        echo "${parts[0]}"
    fi
}

function kube::host::get-subdomain {
    local parts=($(kube::host::_parse))
    if kube::host::isnt-statefulset && [[ ${#parts[@]} = 6 ]]; then
        echo "${parts[1]}"
    fi
}

# erlang functions

function erlang::vmargs::get-name {
    local name="${1:-erlang}"
    if net::is-long-hostname; then
        echo "-name $name"
    else
        echo "-sname $name"
    fi
}

# ref: http://erlang.org/doc/apps/erts/crash_dump.html
function erlang::set-erl-dump {
    local path
    if kube::is-kubernetes; then
        path=/dev/termination-log
    else
        path=~/erlang-crash.dump
    fi
    export ERL_CRASH_DUMP="$path"
}

# kazoo functions

function kazoo::sup {
    local ${ERLANG_COOKIE:-$(cat ~/.erlang.cookie)}
    $(which sup) -c "$ERLANG_COOKIE" $@
}

function kazoo::release::get-version {
    if [ -f ~/releases/RELEASES ]; then
        cat ~/.releases/RELEASES | head -1 | cut -d',' -f3 | xargs
    fi
}

function kazoo::erts::get-version {
    if [ -f ~/releases/RELEASES ]; then
        cat ~/.releases/RELEASES | head -1 | cut -d',' -f4 | xargs
    fi
}

function kazoo::build-amqp-uri {
    local host="$1"
    local prefix=${2:-amqp}
    local port=${3:-5672}
    local user=${RABBITMQ_USER:=guest}
    local pass=${RABBITMQ_PASS:=guest}
    printf '%s://%s:%s@%s:%s\n' $prefix "$user" "$pass" $host $port
}

function kazoo::build-amqp-uris {
    local list="$1"
    local prefix="${2:-amqp}"
    local hosts=()
    local host
    for host in ${list//,/ }; do
        hosts+=($(kazoo::build-amqp-uri $host $prefix))
    done
    echo "${hosts[@]}"
}

function kazoo::build-amqp-uri-list {
    local list="$1"
    local label="${2:-amqp_uri}"
    local prefix='amqp'
    local uris=($(kazoo::build-amqp-uris "$list" "$prefix"))
    local hosts
    local host
    for host in "${uris[@]}"; do
        hosts+="$label = \"$host\"\n"
    done
    echo -e "$hosts" | head -n -1
}

function shell::is-interactive {
    [[ $- =~ i ]]
}

function shell::is-not-interactive {
    ! shell::is-interactive
}
