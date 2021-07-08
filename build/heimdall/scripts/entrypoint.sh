#!/bin/sh

# exit script on any error
set -e

# Set Heimdall Home Directory
HEIMDALLD_HOME=/root/.heimdalld

if [ ! -f "$HEIMDALLD_HOME/config/config.toml" ];
then
    echo "setting up initial configurations"
    heimdalld init
    cd $HEIMDALLD_HOME/config

    echo "removing autogenerated genesis file"
    rm genesis.json

    echo "downloading launch genesis file"
    wget https://raw.githubusercontent.com/maticnetwork/launch/master/mainnet-v1/without-sentry/heimdall/config/genesis.json

    echo "overwriting toml config lines"
    # config.toml
    # CORS
    sed -i "s#^cors_allowed_origins.*#cors_allowed_origins = [\"*\"]#" config.toml
    # SEEDS
    sed -i "s#^seeds.*#seeds = \"${BOOTNODES:-"f4f605d60b8ffaaf15240564e58a81103510631c@159.203.9.164:26656,4fb1bc820088764a564d4f66bba1963d47d82329@44.232.55.71:26656"}\"#" config.toml
    # heimdall-config.toml
    # BOR
    sed -i "s#^bor_rpc_url.*#bor_rpc_url = \"http://bor:8545\"#" heimdall-config.toml
    # ETH1
    sed -i "s#^eth_rpc_url.*#eth_rpc_url = \"${ETH1_RPC_URL}\"#" heimdall-config.toml
    # RABBITMQ
    sed -i "s#^amqp_url.*#amqp_url = \"amqp://guest:guest@rabbitmq:5672\"#" heimdall-config.toml
fi

echo "$BOOTSTRAP"
echo "${SNAPSHOT_DATE}"

if [ "${BOOTSTRAP}" == 1 ] && [ -n "${SNAPSHOT_DATE}" ];
then
  echo "downloading snapshot from ${SNAPSHOT_DATE}"
  mkdir -p ${HEIMDALLD_HOME}/data
  wget -c https://matic-blockchain-snapshots.s3.amazonaws.com/matic-mainnet/heimdall-fullnode-snapshot-${SNAPSHOT_DATE}.tar.gz -O - | tar -xz -C ${HEIMDALLD_HOME}/data
fi

if [ -n "$REST_SERVER" ];
then
  EXEC="heimdalld rest-server --chain-id=137 --laddr=tcp://0.0.0.0:1317 --max-open=1000 --node=tcp://heimdalld:26657 --trust-node=true"
else
  EXEC="heimdalld start --moniker=$MONIKER --fast_sync --p2p.laddr=tcp://0.0.0.0:26656 --p2p.upnp=false --pruning=syncable --rpc.laddr=tcp://0.0.0.0:26657 --with-tendermint=true"
fi

${EXEC}
