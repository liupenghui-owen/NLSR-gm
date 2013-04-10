#Use this script to setup your keys. 
#!/bin/bash

EXPECTED_ARGS=3 #site, operator, router
E_BADARGS=65
if [ $# -ne $EXPECTED_ARGS ]
then
  echo "Usage: `basename $0` <site name> <operator name> <router name>"
  echo "Example: `basename $0` memphis.edu user1 memphis.edu/cs/rtr1 (full router name without /ndn/ prefix" 
  exit $E_BADARGS
fi


RESULT=`ps -a | sed -n /ccnr/p`

if [ "${RESULT:-null}" = null ]; then
  echo "ccnr not running, quitting"
  exit
fi


KSUITE=${HOME}/ndn-testbed-key-suite
echo $KSUITE
if [ ! -d ${KSUITE} ]; then
    echo "This script requires key signing suite available at:"
	echo "git://github.com/named-data/ndn-testbed-key-suite.git"
	echo "If you already have it, set the variable KSUITE of the script accordingly"
	exit
fi

SITE=$1
OP=$2
RTR=$3

if [ ! -d ${SITE}_key ]; then
	mkdir ${SITE}_key
	ccninitkeystore ${SITE}_key
fi

if [ ! -d ${OP}_key ]; then
	mkdir ${OP}_key
	ccninitkeystore ${OP}_key
fi

if [ ! -d "router_key" ]; then
	mkdir router_key
	ccninitkeystore router_key
fi

if [ ! -d "nlsr_key" ]; then
	mkdir nlsr_key
	ccninitkeystore nlsr_key
fi




$KSUITE/bin/ndn-extract-public-key.sh -i ${SITE}_key/.ccnx/.ccnx_keystore -o ${SITE}_key/$SITE.pem
$KSUITE/bin/ndn-extract-public-key.sh -i ${OP}_key/.ccnx/.ccnx_keystore -o ${OP}_key/$OP.pem
$KSUITE/bin/ndn-extract-public-key.sh -i router_key/.ccnx/.ccnx_keystore -o router_key/router.pem
$KSUITE/bin/ndn-extract-public-key.sh -i nlsr_key/.ccnx/.ccnx_keystore -o nlsr_key/nlsr.pem

.$KSUITE/sign.sh -s

#signing operator key
echo "$KSUITE/bin/ndn-publish-key.sh -i "$OP" -a "$SITE" -f ${OP}_key/$OP.pem -F ${SITE}_key/.ccnx/ -P /ndn/keys/$SITE -p /ndn/keys/$SITE/%C1.O.N.Start/$OP -x 365"
$KSUITE/bin/ndn-publish-key.sh -i "$OP" -a "$SITE" -f ${OP}_key/$OP.pem -F ${SITE}_key/.ccnx/ -P /ndn/keys/$SITE -p /ndn/keys/$SITE/%C1.O.N.Start/$OP -x 365

#signing routing key
echo "$KSUITE/bin/ndn-publish-key.sh -i "$RTR" -a "$SITE" -f router_key/router.pem -F ${OP}_key/.ccnx/ -P /ndn/keys/$SITE/%C1.O.N.Start/$OP -p /ndn/keys/$SITE/%C1.R.N.Start/ndn/$RTR -x 365"
$KSUITE/bin/ndn-publish-key.sh -i "$RTR" -a "$SITE" -f router_key/router.pem -F ${OP}_key/.ccnx/ -P /ndn/keys/$SITE/%C1.O.N.Start/$OP -p /ndn/keys/$SITE/%C1.R.N.Start/ndn/$RTR -x 365

#signing nlsr key
echo "$KSUITE/bin/ndn-publish-key.sh -i "NLSR" -a "$RTR" -f nlsr_key/nlsr.pem  -F router_key/.ccnx/ -P /ndn/keys/$SITE/%C1.R.N.Start/ndn/$SITE/$RTR -p /ndn/keys/$SITE/%C1.R.N.Start/ndn/$RTR/nlsr -x 365"
$KSUITE/bin/ndn-publish-key.sh -i "NLSR" -a "$RTR" -f nlsr_key/nlsr.pem  -F router_key/.ccnx/ -P /ndn/keys/$SITE/%C1.R.N.Start/ndn/$SITE/$RTR -p /ndn/keys/$SITE/%C1.R.N.Start/ndn/$RTR/nlsr -x 365
