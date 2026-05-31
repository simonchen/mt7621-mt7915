#!/bin/sh /etc/rc.common
START=99

start() {
	COUNT=0
	while ! brctl show | grep -q "lan" && [ $COUNT -lt 30 ]; do
		sleep 1
		COUNT=$((COUNT + 1))
	done
	ifconfig rax0 up
	ifconfig apclix0 up
	ifconfig ra0 up
	ifconfig apcli0 up

	brctl addif br-lan rax0 2>/dev/null
	brctl addif br-lan ra0 2>/dev/null

	iwpriv apcli0 set ApCliEnable=0
	ssid=$(grep -e "ApCliSsid=" /etc/wireless/mt7615/mt7615.1.5G.dat)
	enable=$(grep -e "ApCliEnable=" /etc/wireless/mt7615/mt7615.1.5G.dat)
	iwpriv apcli0 set "$ssid"
	iwpriv apcli0 set ApCliAutoConnect=3
    	iwpriv apcli0 set "$enable"
    	iwpriv apclix0 set ApCliEnable=0
	ssid=$(grep -e "ApCliSsid=" /etc/wireless/mt7615/mt7615.1.2G.dat)
	enable=$(grep -e "ApCliEnable=" /etc/wireless/mt7615/mt7615.1.2G.dat)
	iwpriv apclix0 set "$ssid"
	iwpriv apclix0 set ApCliAutoConnect=3
    	iwpriv apclix0 set "$enable"
    	kick=$(grep -e "KickStaRssiLow=" /etc/wireless/mt7615/mt7615.1.5G.dat)
    	iwpriv ra0 set "$kick"
    	kick=$(grep -e "KickStaRssiLow=" /etc/wireless/mt7615/mt7615.1.2G.dat)
    	iwpriv rax0 set "$kick"
}



