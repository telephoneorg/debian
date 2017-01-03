# populate environment
if [[ -f /etc/environment.d ]]; then
    eval $(cat /etc/environment.d/*)
    export $(cat /etc/environment.d/* | grep -v ^# | grep '[^[:blank:]]' | cut -d= -f1)
fi