#!/bin/bash
echo `ifconfig eth0 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://'` namenode| cat >> /etc/hosts
