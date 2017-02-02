# Debian Base Image

![docker pulls](https://img.shields.io/docker/pulls/callforamerica/debian.svg)
![build status](https://travis-ci.org/sip-li/debian.svg?branch=master)

## Maintainer

Joe Black <joe@valuphone.com> [github](https://github.com/joeblackwaslike)

## Introduction

The purpose of this project was to create a super minimal docker base image based on debian.  This image will work with pretty much all recent debian releases, but is only tested with jessie.  To use a release other than jessie simply export the environment variable RELEASE to something other than `debian/jessie` before running base-repo/build.sh  or base-repo/push.sh.

This project makes extensive use of the tklx/base project and it would feel wrong to not mention it:  [tklx/base](https://github.com/tklx/base)

Pull requests with improvements always welcome.


## Featuring

* Everything that makes `tklx/base` amazing.

* Added the following packages to required:
    * netcat
    * procpcs and requirements: libncursesw5, libprocps3

* Changes to `unit.d/apt.conf.d`:
    * [docker-autoremove-suggests](base-repo/unit.d/apt/overlay/etc/apt/apt.conf.d/docker-autoremove-suggests)
    * [no-install-suggests](base-repo/unit.d/apt/overlay/etc/apt/apt.conf.d/no-install-reccomends)

* Changes to `unit.d/etc-skel`
    * set .bashrc to `! shopt -q login_shell && . /etc/profile`

* Created new unit in `unit.d/std-dirs`:
    * creates two directories at the root of the filesystem: {volumes,data}

* Created new unit in `unit.d/etc-profile-d`:
    * Conf file sets up dircolors
    * Additions to /etc/profile.d/ to initialize a more proper shell environment
        * [10-home-bin-path.sh](base-repo/unit.d/etc-profile-d/overlay/etc/profile.d/10-home-bin-path.sh)
        * [30-shell-env.sh](base-repo/unit.d/etc-profile-d/overlay/etc/profile.d/30-shell-env.sh)
        * [50-prompt-colors.sh](base-repo/unit.d/etc-profile-d/overlay/etc/profile.d/50-prompt-colors.sh)

* Created new unit in `unit.d/util` (see util section below for details):
    * Added a upx'd dumb-init to overlay/
    * Added gosu to overlay/usr/local/bin/
    * Added kubernetes hostname wrapper to overlay/usr/local/bin/kube-hostname-wrapper
    * Added some utility scripts to overlay/usr/local/bin:
        * [containerid](base-repo/unit.d/util/overlay/usr/local/bin/containerid)
        * [detect-proxy](base-repo/unit.d/util/overlay/usr/local/bin/detect-proxy)
        * [fix-kube-hostname](base-repo/unit.d/util/overlay/usr/local/bin/fix-kube-hostname)
        * [persistent-volume-util](base-repo/unit.d/util/overlay/usr/local/bin/persistent-volume-util)
        * [write-erlang-cookie](base-repo/unit.d/util/overlay/usr/local/bin/write-erlang-cookie)


## Utils

Some utility scripts were added to /usr/local/bin that deserve some mention.  They won't be discussed in depth here, but are well documented inside each script itself.


### `dumb-init`

[github](https://github.com/Yelp/dumb-init)

This is a simple and lightweight process supervisor that handles reaping zombies and properly passing signals.  It assumes PID1 and implements the expected interface of an application running as PID1.  Without dumb-init process supervision in containers is broken because the default signal handlers are disabled when running as PID1.  Without dumb-init your containers applications will not be able to shut down cleanly.


### `gosu`

[github](https://github.com/tianon/gosu)

su and sudo have very strange TTY and signal forwarding behavior that break signalling as well as not passing things like PATH when preserving environment.  Overall it is unsuitable for container use, and gosu was created to address this specific problem and maintains parity with docker's own user implementation.  The version included has been compressed with UPX.

#### Usage:
    `exec gosu <user> <cmd>`


### `kube-hostname-wrapper`

[github](https://github.com/joeblackwaslike/kube-hostname-wrapper)

This is a golang compiled binary compressed with upx, designed to address certain limitations in kubernetes that make running applications that depend on hostname resolution inside the container to match outside the container.  See repo for more.

#### Usage: [not intended for direct usage]


### `containerid`

[containerid](base-repo/unit.d/util/overlay/usr/local/bin/containerid)

Echo's the current container's id to stdout.

#### Usage:
    `containerid [args]`

### `detect-proxy`

[detect-proxy](base-repo/unit.d/util/overlay/usr/local/bin/detect-proxy)

Used when building a container locally, auto detects a local proxy running on the bridgeip address and/or apt-cacher proxy and sets up `http_proxy` and Apt appropriately.  

Proxy detection tests the bridge ip for ports 3142 for apt-cacher and 3128 for squid or other generic http proxy.

#### Usage:
  `detect-proxy enable` (at beginning of build script)
  `detect-proxy disable` (at end of build script)


### `fix-kube-hostname`

[fix-kube-hostname](base-repo/unit.d/util/overlay/usr/local/bin/fix-kube-hostname)

Uses the `kube-hostname-wrapper` script above and links it as hostname in /usr/local/bin.  Also makes sure proper entries are added or removed from /etc/hosts, that /etc/hostname is set, and HOSTNAME is exported.

#### Usage:
    `fix-kube-proxy enable`: enable's hostname fix
    `fix-kube-proxy disable`: disable's hostname fix


### `write-erlang-cookie`

[write-erlang-cookie](base-repo/unit.d/util/overlay/usr/local/bin/write-erlang-cookie)

Writes the value of `ERLANG_COOKIE:=insecure-cookie` to `~/.erlang-cookie`

#### Usage:
    `write-erlang-cookie` : Write's erlang cookie
    `write-erlang-cookie disable`: Removes erlang cookie


### `persist-volume-util`

[persist-volume-util](base-repo/unit.d/util/overlay/usr/local/bin/persist-volume-util)

Created for use under kubernetes, but simply following conventions for mount points will satisfy this tool's only requirements.  

Links from the persist volume directory to a standard directory under /data if PERSISTENT_STORAGE_ENABLED = true, otherwise just creates the expected directory.  See script for full details.

#### Usage:
    `persist-volume-util link <app-name>`: creates the proper /data/<app-name> link for use inside entrypoint scripts.


## Directions

1. Checkout repository
2. Make changes to units or add new units under `base-repo/unit.d`
3. Make changes to packages installed under `base-repo/plan/`
4. `make build`
5. `make build-docker`
6. test that your image works as expected
7. either docker push the image to your docker repository, or push to your git repo and schedule an automatic build on docker hub.


## Gotchas

### Problem:

I ran `apt-get install curl` and curl isn't working for sites with TLS

### Answer:

This minimal distribution has some changes made to apt.conf.d that alter apt-get's behavior.  Suggested and reccomended packages are no longer installed by default, and closely equivalent to running `apt-get install --no-install-reccomends <pkg>`.  Therefore you need to be more explicit if what you are installing depends on packages that are only reccomended or suggested.  In the case of curl, you can fix this by issuing `apt-get install -y curl ca-certificates` in order to pull in the root ca's and also setup requirements such as gnutls.
