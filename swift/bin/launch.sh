#!/bin/sh
service rsyslog start
service rsync start
service memcached start
service swift-proxy start
service swift-container start
service swift-account start
service swift-object start
apachectl -DFOREGROUND
