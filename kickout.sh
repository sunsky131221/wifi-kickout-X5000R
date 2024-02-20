#!/bin/sh

### kickout.sh #####

# threshold (dBm), always negative 
thr_2=-50
thr_5=-65

# mode (string) = "white" or "black", always minuscule !
# black: only the clients in the blacklist can be kicked out.
# white: kick out all the clients except those in the whitelist.
mode="white"

# In "black" mode, only the clients in the blacklist can be kicked out.
blacklist="00:00:00:00:00:00 00:00:00:00:00:00"

# In "white" mode, the clients in the whitelist will not be kicked out.
whitelist="00:00:00:00:00:00 00:00:00:00:00:00"

# Specified logfile
logfile="/tmp/kickout-wifi.log"
datetime=`date +%Y-%m-%d_%H:%M:%S`
if [[ ! -f "$logfile" ]]; then
	echo "creating kickout-wifi logfile: $logfile"
	echo "$datetime: kickout-wifi log file created." > $logfile
fi

# function deauth
function deauth () 
{
	mac=$1
	wlan=$2
	rssi=$3
 	thr=$4
	echo "kicking $mac with $rssi dBm (thr=$thr) at $wlan" | logger
	echo "$datetime: kicking $mac with $rssi dBm (thr=$thr) at $wlan" >> $logfile
	ubus call hostapd.$wlan del_client \
	"{'addr':'$mac', 'reason':5, 'deauth':true, 'ban_time':3000}"
# "ban_time" prohibits the client to reassociate for the given amount of milliseconds.
}

# wlanlist for multiple wlans (e.g., 5GHz)
wlanlist_5=$(ifconfig | grep phy1 | grep -v sta | awk '{ print $1 }')
#loop for each wlan
for wlan in $wlanlist_5
do
	maclist=""; maclist=$(iw $wlan station dump | grep Station | awk '{ print $2 }')
	#loop for each associated client (station)
	for mac in $maclist
	do
		echo "$blacklist" | grep -q -e $mac
		inBlack=$?	#0 for in Blacklist!
		echo "$whitelist" | grep -q -e $mac
		inWhite=$?	#0 for in Whitelist!

		if [ $mode = "black" -a $inBlack -eq 0 ] || [ $mode = "white" -a $inWhite -ne 0 ]
			then
				rssi=""; rssi=$(iw $wlan station get $mac | \
				grep "signal avg" | awk '{ print $3 }')
				if [ $rssi -lt $thr_5 ]
					then
						##skip wlan if necessary
						#if [ $wlan = wlan0 ];then
						#	echo "ignored $mac with $rssi dBm (thr=$thr) at $wlan" | logger
						#	echo "$datetime: ignored $1 with $rssi dBm (thr=$thr) at $wlan" >> $logfile
						#	continue
						#fi
						##
						deauth $mac $wlan $rssi $thr_5
				fi
		fi
####
	done
done
####
# wlanlist for multiple wlans (e.g., 2.4GHz)
wlanlist_2=$(ifconfig | grep phy0 | grep -v sta | awk '{ print $1 }')
for wlan in $wlanlist_2
do
	maclist=""; maclist=$(iw $wlan station dump | grep Station | awk '{ print $2 }')
	#loop for each associated client (station)
	for mac in $maclist
	do
		echo "$blacklist" | grep -q -e $mac
		inBlack=$?	#0 for in Blacklist!
		echo "$whitelist" | grep -q -e $mac
		inWhite=$?	#0 for in Whitelist!

		if [ $mode = "black" -a $inBlack -eq 0 ] || [ $mode = "white" -a $inWhite -ne 0 ]
			then
				rssi=""; rssi=$(iw $wlan station get $mac | \
				grep "signal avg" | awk '{ print $3 }')
				if [ $rssi -lt $thr_2 ]
					then
						##skip wlan if necessary
						#if [ $wlan = wlan0 ];then
						#	echo "ignored $mac with $rssi dBm (thr=$thr) at $wlan" | logger
						#	echo "$datetime: ignored $1 with $rssi dBm (thr=$thr) at $wlan" >> $logfile
						#	continue
						#fi
						##
						deauth $mac $wlan $rssi $thr_2
				fi
		fi
####
	done
done
# sleep 10s and call itself.
#sleep 10; /bin/sh $0 &

###
