#!/bin/bash

set -x 

QUICKSILVERD_HOME="/tmp/quicksilverd$(date +%s)"
RANDOM_KEY="randomquicksilverdvalidatorkey"
CHAIN_ID=quicksilver-1
DENOM=uqck
VALIDATOR_COINS=10000000000$DENOM
MAXBOND=51000000
GENTX_FILE=$(find ./$CHAIN_ID/gentx -iname "*.json")
LEN_GENTX=$(echo ${#GENTX_FILE})
QUICKSILVERD_TAG="v0.6.4-rc.0"

# Gentx Start date
start="2021-10-11 01:00:00Z"
# Compute the seconds since epoch for start date
stTime=$(date --date="$start" +%s)

# Gentx End date
end="2022-09-04 21:00:00Z"
# Compute the seconds since epoch for end date
endTime=$(date --date="$end" +%s)

# Current date
current=$(date +%Y-%m-%d\ %H:%M:%S)
# Compute the seconds since epoch for current date
curTime=$(date --date="$current" +%s)

if [[ $curTime < $stTime ]]; then
    echo "start=$stTime:curent=$curTime:endTime=$endTime"
    echo "Gentx submission is not open yet."
    exit 1
else
    if [[ $curTime > $endTime ]]; then
        echo "start=$stTime:curent=$curTime:endTime=$endTime"
        echo "Gentx submission is closed"
        exit 1
    else
        echo "Gentx is now open"
        echo "start=$stTime:curent=$curTime:endTime=$endTime"
    fi
fi

if [ $LEN_GENTX -eq 0 ]; then
    echo "No new gentx file found."
    exit 1
else
    set -e

    echo "GentxFiles:"
    echo $GENTX_FILE

    echo "-> Init quicksilverd..."

    git clone https://github.com/ingenuity-build/quicksilver
    cd quicksilver
    git checkout $QUICKSILVERD_TAG
    make build
    chmod +x ./bin/quicksilverd

    ./bin/quicksilverd keys add $RANDOM_KEY --keyring-backend test --home $QUICKSILVERD_HOME

    ./bin/quicksilverd init --chain-id $CHAIN_ID validator --home $QUICKSILVERD_HOME

    echo "-> Fetch genesis..."
    rm -rf $QUICKSILVERD_HOME/config/genesis.json
    cp ../$CHAIN_ID/pre-genesis.json $QUICKSILVERD_HOME/config/genesis.json

    # this genesis time is different from original genesis time, just for validating gentx.
    sed -i '/genesis_time/c\   \"genesis_time\" : \"2021-09-02T16:00:00Z\",' $QUICKSILVERD_HOME/config/genesis.json

    find ../$CHAIN_ID/gentx -iname "*.json" -print0 |
        while IFS= read -r -d '' line; do
            GENACC=$(cat $line | sed -n 's|.*"delegator_address":"\([^"]*\)".*|\1|p')
            denomquery=$(jq -r '.body.messages[0].value.denom' $line)
            amountquery=$(jq -r '.body.messages[0].value.amount' $line)

            echo $GENACC
            echo $amountquery
            echo $denomquery

            # only allow $DENOM tokens to be bonded
            if [ $denomquery != $DENOM ]; then
                echo "invalid denomination"
                exit 1
            fi

            # limit the amount that can be bonded
            if [ $amountquery -gt $MAXBOND ]; then
                echo "bonded too much: $amountquery > $MAXBOND"
                exit 1
            fi

            ./bin/quicksilverd add-genesis-account $(jq -r '.body.messages[0].delegator_address' $line) $VALIDATOR_COINS --home $QUICKSILVERD_HOME
        done

    mkdir -p $QUICKSILVERD_HOME/config/gentx/

    # add submitted gentxs
    cp -r ../$CHAIN_ID/gentx/* $QUICKSILVERD_HOME/config/gentx/

    echo "-> Collect gentxs..."
    ./bin/quicksilverd collect-gentxs --home $QUICKSILVERD_HOME &> log.txt
    sed -i '/persistent_peers =/c\persistent_peers = ""' $QUICKSILVERD_HOME/config/config.toml
    sed -i '/minimum-gas-prices =/c\minimum-gas-prices = "0.25uqck"' $QUICKSILVERD_HOME/config/app.toml

    ./bin/quicksilverd validate-genesis --home $QUICKSILVERD_HOME

    echo "-> Start node..."
    ./bin/quicksilverd start --home $QUICKSILVERD_HOME &

    sleep 90s

    echo "...checking network status.."

    ./bin/quicksilverd status --node http://localhost:26657

    echo "...Cleaning the stuff..."
    killall quicksilverd >/dev/null 2>&1
    rm -rf $QUICKSILVERD_HOME >/dev/null 2>&1
fi
