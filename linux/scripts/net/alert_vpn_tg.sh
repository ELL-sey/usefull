#!/bin/sh
MYDATE=$(/bin/date +'%Y/%m/%d %H:%M:%S')
if [ "$script_type" = "client-connect" ]; then
  /usr/local/bin/curl -s -k "https://api.telegram.org/bot<TOKEN>/sendMessage" -d text="$MYDATE - VPN connection established. Username $common_name with external IP address $trusted_ip obtains internal IP address $ifconfig_pool_remote_ip." -d chat_id=<CHAT_ID>
elif  [ "$script_type" = "client-disconnect" ]; then
  /usr/local/bin/curl -s -k "https://api.telegram.org/bot<TOKEN>/sendMessage" -d text="$MYDATE - VPN connection terminated. Username $common_name with external IP address $trusted_ip frees internal IP address $ifconfig_pool_remote_ip." -d chat_id=<CHAT_ID>
fi
exit 0
