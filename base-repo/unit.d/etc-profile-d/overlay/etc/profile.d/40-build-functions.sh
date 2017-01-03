function build::apt::get-version {
    local app=${1:-$APP}
    local vvar=${2:-$app}; vvar=${vvar^^}_VERSION
    local version=${!vvar}
    apt-cache madison $app | awk '{print $3}' | grep $version | sort -rn | head -1
}

function build::apt::add-key {
    local key="$1"
    local server="${2:-ha.pool.sks-keyservers.net}"
    log::m-info "Adding key: $key to apt ..."
    apt-key adv --keyserver $server --recv-keys $key
}

function build::user::create {
    local user="${1:-$USER}"
    log::m-info "Creating user and group: $user ..."
    useradd --system --home-dir ~ --create-home --shell /bin/false --user-group $user
}
