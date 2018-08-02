#!/bin/bash

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Build your first network (BYFN) end-to-end test"
echo
CHANNEL_NAME="$1"
DELAY="$2"
LANGUAGE="$3"
TIMEOUT="$4"
VERBOSE="$5"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${LANGUAGE:="golang"}
: ${TIMEOUT:="10"}
: ${VERBOSE:="false"}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=5

CC_SRC_PATH="github.com/chaincode/chaincode_example02/go/"
if [ "$LANGUAGE" = "node" ]; then
	CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/node/"
fi

echo "Channel name : "$CHANNEL_NAME

# import utils
. scripts/utils.sh

createChannel() {
	setGlobals 0 1

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		peer channel create -o orderer.zone.com.ng:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx >&log.txt
		res=$?
                set +x
	else
				set -x
		peer channel create -o orderer.zone.com.ng:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		res=$?
				set +x
	fi
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel '$CHANNEL_NAME' created ===================== "
	echo
}

joinChannel () {
	for org in 1; do
	    for peer in 0 1; do
		joinChannelWithRetry $peer $org
		echo "===================== peer${peer}.${ORGDOMAIN} joined channel '$CHANNEL_NAME' ===================== "
		sleep $DELAY
		echo
	    done
	done
}

## Create channel
echo "Creating channel..."
createChannel

## Join all the peers to the channel
echo "Having all peers join the channel..."
joinChannel

## Set the anchor peers for each org in the channel
echo "Updating anchor peers for uba..."
updateAnchorPeers 0 1
# echo "Updating anchor peers for fcmb..."
# updateAnchorPeers 0 2

## Install chaincode on peer0.uba and peer1.uba
echo "Installing chaincode on peer0.uba..."
installChaincode 0 1
echo "Install chaincode on peer1.uba..."
installChaincode 1 1

# Instantiate chaincode on peer0.fcmb
# echo "Instantiating chaincode on peer0.fcmb..."
# instantiateChaincode 0 2

#Instantiate chaincode on peer0.uba
echo "Instantiating chaincode on peer0.uba..."
instantiateChaincode 0 1

# Query chaincode on peer0.uba
echo "Querying chaincode on peer0.uba..."
chaincodeQuery 0 1 100

# Invoke chaincode on peer0.uba and peer0.fcmb
echo "Sending invoke transaction on peer0.uba peer0.fcmb..."
chaincodeInvoke 0 1

## Install chaincode on peer1.fcmb
# echo "Installing chaincode on peer1.fcmb..."
# installChaincode 1 2

# Query on chaincode on peer1.fcmb, check if the result is 90
echo "Querying chaincode on peer1.uba..."
chaincodeQuery 1 1 90

echo
echo "========= All GOOD, BYFN execution completed =========== "
echo

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0
