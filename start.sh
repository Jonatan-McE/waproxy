#!/bin/bash

# Start RCDEVS waproxy service
if [ ! "$(ls -A /opt/waproxy/conf/)" ]; then
  echo ">Copying default WAProxy config files"
  cp -r --preserve=all /opt/waproxy/.conf/* /opt/waproxy/conf/
fi
if [ ! -f /opt/waproxy/temp/.setup ]; then
    if [ -z "$WEBADM_IP" ]; then
        echo "Missing WEBADM_IP environment variable"
        exit 1
    fi
    if [ -z "$WAPROXY_URL" ]; then
        echo "Missing WAPROXY_URL environment variable"
        exit 1
    fi
    echo ">-- Checking if WebADM is ready --"
    while [[ ! `wget --no-check-certificate --no-cookies --timeout=5 --delete -S https://$WEBADM_IP/cacert/ 2>&1 | grep 'HTTP/1.1 200'` ]]; do
        sleep 5
    done
    if [ -z "$WAPROXY_CERT_URL" ]; then
        echo ">Running WAProxy silent setup (With Let's Encrypt)"
    	printf "$WAPROXY_URL\n$WEBADM_IP\n\ny\ny\nn\n" | /opt/waproxy/bin/setup
    else
       echo ">Running WAProxy silent setup (Without Let's Encrypt)"
       printf "$WAPROXY_URL\n$WEBADM_IP\n\ny\ny\ny\n$WAPROXY_CERT_URL\n" | /opt/waproxy/bin/setup
    fi
fi
echo ">Starting WAProxy service"
/opt/waproxy/bin/waproxy start
status=$?
if [ $status -ne 0 ]; then
    echo "Failed to start waproxy: $status"
    exit $status
fi

# Service monitoring loop
echo "-- Starting process monitoring loop --"
while sleep 60; do
    ps aux |grep rcdevs-waproxy |grep -q -v grep
    PROCESS_1_STATUS=$?
    if [ $PROCESS_1_STATUS -ne 0 ]; then
        echo "One of the processes has already exited."
        exit 1
    fi
done
