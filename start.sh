#!/bin/bash
# Start script for fake AP. Brings up wifi card for AP mode with random mac address, writes this to file.

IF=$1
SSID=$2
WPE_LOG=$3
MAC_FILE=fakeapmac
TMP_FOLDER=/tmp/hostapd-wpe
KEY_PATH=$TMP_FOLDER/certs
CONFIG_TEMPLATE=hostapd_eap.tpl
HOSTAPD_BIN=../hostapd-2.5/hostapd/hostapd

if [ -z "$1" ]; then
  ERROR="Error: missing interface name! "
fi

if [ -z "$2" ]; then
  ERROR=$ERROR"Error: missing SSID! "
fi

if [ -z "$3" ]; then
  ERROR=$ERROR"Error: missing WPE_LOG! "
fi

if [ -n "$ERROR" ]; then
  echo $ERROR
  echo "Usage: $0 interface ssid wpe-log-file"
  exit 1
fi

rm -rf $TMP_FOLDER
mkdir -p $TMP_FOLDER

sudo ifconfig $IF down
MAC=`sudo macchanger -b -r $IF | awk '/New/ {print $3}'`
echo $MAC > $TMP_FOLDER/$MAC_FILE


sed "s|\$AP_SSID|$SSID| ; s|\$AP_IF|$IF| ; s|\$KEY_PATH|$KEY_PATH|" $CONFIG_TEMPLATE > $TMP_FOLDER/hostapd.conf
cp -R certs $KEY_PATH
cp hostapd.eap_user $KEY_PATH

pushd $KEY_PATH
./bootstrap
popd

sudo $HOSTAPD_BIN -F $WPE_LOG $TMP_FOLDER/hostapd.conf
