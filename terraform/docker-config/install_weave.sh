#!/bin/bash

SERVICETOKEN=$1

curl -L https://git.io/scope -o /usr/local/bin/scope 
chmod a+x /usr/local/bin/scope
scope launch --service-token=$SERVICETOKEN

cat <<! >/etc/rc.local
#!/bin/sh -e
scope launch --service-token=$SERVICETOKEN
exit 0
!
