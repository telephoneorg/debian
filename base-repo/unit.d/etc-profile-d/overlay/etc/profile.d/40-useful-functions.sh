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
    if linux::cmd-exists 'ifconfig'; then
        ifconfig eth0 | grep 'inet ' | cut -d':' -f2 | awk '{print $1}'
    elif linux::cmd-exists 'ip'; then
        ip -o -f inet addr show eth0 | sed 's/.*inet \(.*\)\/.*/\1/'
    elif linux::cmd-exists 'hostname'; then
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
    local module="$3"
    local symbol="${symbol_map[$type]}"
    local color="${color_map[$type]}"
    local time="$(log::get-time)"
    echo -e "\E[${color}m[${symbol}]\E[0m $time ${type^^} $module $msg" >&2
}

function log::info {
    local msg="$1"
    local module="$2"
    log::_show-msg "$msg" 'info' "$module"
}

function log::error {
    local msg="$1"
    local module="$2"
    log::_show-msg "$msg" 'error' "$module"
}

function log::warn {
    local msg="$1"
    local module="$2"
    log::_show-msg "$msg" 'warn' "$module"
}

# linux functions

function linux::echo-file {
    local path="$1"
    if [[ -f $path ]]; then
        echo $(cat "$path")
    fi
}

function linux::cmd-exists {
    local cmd="$1"
    hash "$cmd" > /dev/null 2>&1
}

function linux::cap::is-enabled {
    local name="$1"
    capsh --print | grep -q cap_${name,,}
}

function linux::cap::show-warning {
    local name="$1"
    echo "The cap CAP_${name^^} is restricted in this container.
It's recommended to run container with --cap-add ${name^^}"
}

# net functions

function net::is-long-hostname {
    [[ $(hostname -f) =~ \. ]]
}

function net::is-short-hostname {
    ! base::is-long-hostname
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
    linux::echo-file "$path"
}

function kube::sa::get-token {
    local path=$(kube::sa::_get-path 'token')
    linux::echo-file "$path"
}

function kube::host::_parse {
    local host=$(hostname -f)
    echo "${host//\./ }"
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
    if net::is-long-hostname; then
        echo '-name couchdb'
    else
        echo '-sname couchdb'
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

function kazoo::get-release {
    if [ -f ~/releases/RELEASES ]; then
        cat ~/.releases/RELEASES | head -1 | cut -d',' -f3 | xargs
    fi
}

function kazoo::get-erts {
    if [ -f ~/releases/RELEASES ]; then
        cat ~/.releases/RELEASES | head -1 | cut -d',' -f4 | xargs
    fi
}
