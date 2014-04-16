# Start script for fake AP. Brings up wifi card for AP mode with random mac address, writes this to file.

IF=$1
SSID=$2
WPE_LOG=$3
MAC_FILE=fakeapmac
TMP_FOLDER=/mnt/obb/hostapd
PERSIST_FOLDER=/data/wpelog
KEY_PATH=$TMP_FOLDER/certs
CONFIG_TEMPLATE=hostapd_eap.tpl
HOSTAPD_BIN=/system/bin/hostapd-eap

if [ -z "$1" ]; then
  ERROR="Error: missing interface name! "
fi

if [ -z "$2" ]; then
  ERROR=$ERROR"Error: missing SSID! "
fi

if [ -z "$3" ]; then
  WPE_LOG=$PERSIST_FOLDER/`date +%Y%m%d-%H%M%S`.log
  echo "Missing WPE_LOG! using $WPE_LOG"
fi

if [ -n "$ERROR" ]; then
  echo $ERROR
  echo "Usage: $0 interface ssid wpe-log-file"
  exit 1
fi

rm -r $TMP_FOLDER
mkdir -p $TMP_FOLDER

ip link set dev wlan0 down
MAC=`macchanger -a $IF | awk '/New/ {print $3}'`
echo $MAC > $TMP_FOLDER/$MAC_FILE
ip link set dev wlan0 up


sed "s|\$AP_SSID|$SSID| ; s|\$AP_IF|$IF| ; s|\$KEY_PATH|$KEY_PATH|" $CONFIG_TEMPLATE > $TMP_FOLDER/hostapd.conf
cp -R certs $KEY_PATH
cp hostapd.eap_user $KEY_PATH

cd $KEY_PATH
./bootstrap
cd $TMP_FOLDER
chmod -R 0755 $TMP_FOLDER
chown wifi:wifi $TMP_FOLDER
echo "starting hostapd..."
$HOSTAPD_BIN -F $WPE_LOG $TMP_FOLDER/hostapd.conf &
sleep 4
echo "printing wpe log:"
tail -f $WPE_LOG
echo "foregrounding hostapd"
fg
killall hostapd-eap
macchanger -p $IF
echo "restored mac and exited"
