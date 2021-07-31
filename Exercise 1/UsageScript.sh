#!/bin/bash
#Author: Rameshkumar
#Purpose: Show the current CPU/DISK/Network Usage


#Cpu Uaage

cpu_usage=$(top -b -n2 -p 1 | fgrep "Cpu(s)" | tail -1 | awk -F'id,' -v prefix="$prefix" '{ split($1, vs, ","); v=vs[length(vs)]; sub("%", "", v); printf "%s%.1f%%\n", prefix, 100 - v }')

dt=$(date "+%Y-%m-%d %H:%M:")

cpu_usage="$DT CPU: $cpu_usage"

echo "=============================="
echo "CPU USAGE"
echo "=============================="
echo $cpu_usage
echo "=============================="

#Disk Usage

echo "DISK USAGE"
echo "=============================="
echo ""disk_usage" \n `df -H | grep -vE '^Filesystem|tmpfs|cdrom|udev' | awk '{ print $1 " " $5}'` \n"
echo "=============================="

#Network Usage

rx_current=$(cat /proc/net/dev | grep 'eth' | tr : " " | awk '{print $2}')
tx_current=$(cat /proc/net/dev | grep 'eth' | tr : " " | awk '{print $10}')

rx_conv=`expr $rx_current / 1024`
tx_conv=`expr $tx_current / 1024`
echo "NETWORK USAGE"
echo "=============================="
echo Current Network Receive Speed $rx_conv kB/s
echo Current Network Transmit Speed $tx_conv kB/s
echo "=============================="


#End
