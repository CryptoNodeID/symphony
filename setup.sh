#!/bin/bash
DAEMON_NAME=symphonyd
DAEMON_HOME=$HOME/.symphonyd
SERVICE_NAME=symphonyd
INSTALLATION_DIR=$(dirname "$(realpath "$0")")
CHAIN_ID='symphony-testnet-2'
GENESIS_URL="https://snapshot.cryptonode.id/symphony-testnet/genesis.json"
PEERS="8fc13eb23bb09225d08b4da9bb80ab3b2c008990@sentry2.cryptonode.id:23656,bbf8ef70a32c3248a30ab10b2bff399e73c6e03c@symphony-testnet.rpc.nodex.one:24856"
RPC="https://symphony-testnet-rpc.cryptonode.id:443"
SNAP_RPC="https://symphony-testnet-rpc.cryptonode.id:443"
SEEDS=""
DENOM='note'
REPO="https://github.com/Orchestra-Labs/symphony"
BIN_REPO=""
REPO_DIR="symphony"
BRANCH="v0.2.1"
GOPATH=$HOME/go
VALIDATOR_CREATE_FILE="cli" # json or cli

#Prerequisites
cd ${INSTALLATION_DIR}
if ! grep -q "export GOPATH=" ~/.profile; then
    echo "export GOPATH=$HOME/go" >> ~/.profile
    source ~/.profile
fi
if ! grep -q "export PATH=.*:/usr/local/go/bin" ~/.profile; then
    echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.profile
    source ~/.profile
fi
if ! grep -q "export PATH=.*$GOPATH/bin" ~/.profile; then
    echo "export PATH=$PATH:$GOPATH/bin" >> ~/.profile
    source ~/.profile
fi
source $HOME/.profile
##Check and install Go
GO_VERSION=$(go version 2>/dev/null | grep -oP 'go1\.22\.0')
if [ -z "$(echo "$GO_VERSION" | grep -E 'go1\.22\.0')" ]; then
    echo "Go is not installed or not version 1.22.0. Installing Go 1.22.0..."
    wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz
    sudo rm -rf $(which go)
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
    rm go1.22.0.linux-amd64.tar.gz
else
    echo "Go version 1.22.0 is already installed."
fi
##Check and install cosmovisor
if ! command -v cosmovisor > /dev/null 2>&1 || ! which cosmovisor &> /dev/null; then
    wget https://github.com/cosmos/cosmos-sdk/releases/download/cosmovisor%2Fv1.5.0/cosmovisor-v1.5.0-linux-amd64.tar.gz
    tar -xvzf cosmovisor-v1.5.0-linux-amd64.tar.gz
    rm cosmovisor-v1.5.0-linux-amd64.tar.gz
    sudo cp cosmovisor /usr/local/bin/cosmovisor
fi
sudo apt -qy install curl git jq lz4 build-essential unzip tar

#Prepare Validator Data
read -p "Enter validator name (leave blank for default 'CryptoNodeID'): " VALIDATOR_KEY_NAME
VALIDATOR_KEY_NAME=${VALIDATOR_KEY_NAME:-"CryptoNodeID"}
echo "Get your identity by following this steps: https://docs.harmony.one/home/network/validators/managing-a-validator/adding-a-validator-logo"
read -p "Enter identity (leave blank for default '4a8bc33cee42de0b23bbccbc84aee10fd0cdfc07'): " INPUT_IDENTITY
INPUT_IDENTITY=${INPUT_IDENTITY:-"4a8bc33cee42de0b23bbccbc84aee10fd0cdfc07"}
read -p "Enter website (leave blank for default 'https://cryptonode.id'): " INPUT_WEBSITE
INPUT_WEBSITE=${INPUT_WEBSITE:-"https://cryptonode.id"}
read -p "Enter your email (leave blank for default 'admin@cryptonode.id'): " INPUT_EMAIL
INPUT_EMAIL=${INPUT_EMAIL:-"admin@cryptonode.id"}
read -p "Enter details (leave blank for default 'Created with CryptoNodeID helper. Crypto Validator Node Education Channel. Join us for more details at https://t.me/CryptoNodeID'): " INPUT_DETAILS
INPUT_DETAILS=${INPUT_DETAILS:-"Created with CryptoNodeID helper. Crypto Validator Node Education Channel. Join us for more details at https://t.me/CryptoNodeID"}

if ! grep -q "export DAEMON_NAME=${DAEMON_NAME}" $HOME/.profile; then
    echo "export DAEMON_NAME=${DAEMON_NAME}" >> $HOME/.profile
fi
if ! grep -q "export DAEMON_HOME=${DAEMON_HOME}" $HOME/.profile; then
    echo "export DAEMON_HOME=${DAEMON_HOME}" >> $HOME/.profile
fi
if ! grep -q "export DAEMON_RESTART_AFTER_UPGRADE=false" $HOME/.profile; then
    echo "export DAEMON_RESTART_AFTER_UPGRADE=false" >> $HOME/.profile
fi
if ! grep -q "export DAEMON_ALLOW_DOWNLOAD_BINARIES=true" $HOME/.profile; then
    echo "export DAEMON_ALLOW_DOWNLOAD_BINARIES=true" >> $HOME/.profile
fi
if ! grep -q "export CHAIN_ID=${CHAIN_ID}" $HOME/.profile; then
    echo "export CHAIN_ID=${CHAIN_ID}" >> $HOME/.profile
fi
if ! grep -q "export WALLET=${VALIDATOR_KEY_NAME}" $HOME/.profile; then
    echo "export WALLET=${VALIDATOR_KEY_NAME}" >> $HOME/.profile
fi
source $HOME/.profile

#Display data
echo "DAEMON_NAME=$DAEMON_NAME"
echo "DAEMON_HOME=$DAEMON_HOME"
echo "DAEMON_ALLOW_DOWNLOAD_BINARIES=$DAEMON_ALLOW_DOWNLOAD_BINARIES"
echo "DAEMON_RESTART_AFTER_UPGRADE=$DAEMON_RESTART_AFTER_UPGRADE"
echo "DAEMON_LOG_BUFFER_SIZE=$DAEMON_LOG_BUFFER_SIZE"
echo "Chain id: "${CHAIN_ID}
echo "RPC: "${RPC}
echo "Service name: "${SERVICE_NAME}
echo "======================================================================="
echo "Validator key name: "${VALIDATOR_KEY_NAME}
echo "Identity: "${INPUT_IDENTITY}
echo "Website: "${INPUT_WEBSITE}
echo "Email: "${INPUT_EMAIL}
echo "Details: "${INPUT_DETAILS}

read -p "Press enter to continue or Ctrl+C to cancel"

#Prepare directory
if [ -n "$REPO" ]; then
    rm -rf ${REPO_DIR}
    rm -rf ${DAEMON_HOME}
    #Install daemon
    git clone ${REPO}
    cd ${REPO_DIR}
    git checkout ${BRANCH}
    make build
    mv build/${DAEMON_NAME} ${DAEMON_NAME}
else
    if [[ ${BIN_REPO} == *".tar.gz" ]]; then
        wget -O - ${BIN_REPO} | tar -xzf -
    else
        wget -O ${DAEMON_NAME} ${BIN_REPO}
    fi
    chmod +x ${DAEMON_NAME}
fi

if ! grep -q 'export KEYRING_BACKEND=file' ~/.profile; then
    echo "export KEYRING_BACKEND=file" >> ~/.profile
fi
if ! grep -q 'export WALLET='${VALIDATOR_KEY_NAME} ~/.profile; then
    echo "export WALLET=${VALIDATOR_KEY_NAME}" >> ~/.profile
fi
source ~/.profile

mkdir -p ${DAEMON_HOME}/cosmovisor/genesis/bin
mkdir -p ${DAEMON_HOME}/cosmovisor/upgrades
mv ${DAEMON_NAME} ${DAEMON_HOME}/cosmovisor/genesis/bin/

sudo ln -s ${DAEMON_HOME}/cosmovisor/genesis ${DAEMON_HOME}/cosmovisor/current -f
sudo ln -s ${DAEMON_HOME}/cosmovisor/current/bin/${DAEMON_NAME} /usr/local/bin/${DAEMON_NAME} -f

mkdir -p ${DAEMON_HOME}/cosmovisor/upgrades/$(${DAEMON_NAME} --home ${DAEMON_HOME} version)/bin/
cp $(which ${DAEMON_NAME}) ${DAEMON_HOME}/cosmovisor/upgrades/$(${DAEMON_NAME} --home ${DAEMON_HOME} version)/bin/${DAEMON_NAME}

echo "${DAEMON_NAME} version: "$(${DAEMON_NAME} --home ${DAEMON_HOME} version)
read -p "Press enter to continue or Ctrl+C to cancel"

${DAEMON_NAME} init ${VALIDATOR_KEY_NAME} --chain-id=${CHAIN_ID}
${DAEMON_NAME} config chain-id ${CHAIN_ID}
${DAEMON_NAME} config keyring-backend file
read -p "Do you want to recover wallet? [y/N]: " RECOVER
RECOVER=$(echo "${RECOVER}" | tr '[:upper:]' '[:lower:]')
if [[ "${RECOVER}" == "y" || "${RECOVER}" == "yes" ]]; then
    ${DAEMON_NAME} keys add ${VALIDATOR_KEY_NAME} --recover
else
    ${DAEMON_NAME} keys add ${VALIDATOR_KEY_NAME}
fi
read -p "Save you information and Press enter to continue or Ctrl+C to cancel"
${DAEMON_NAME} keys list

#Set custom ports
read -p "Do you want to use custom port number prefix (y/N)? " use_custom_port
if [[ "$use_custom_port" =~ ^[Yy](es)?$ ]]; then
    read -p "Enter port number prefix (max 2 digits, not exceeding 50): " port_prefix
    while [[ "$port_prefix" =~ [^0-9] || ${#port_prefix} -gt 2 || $port_prefix -gt 50 ]]; do
        read -p "Invalid input, enter port number prefix (max 2 digits, not exceeding 50): " port_prefix
    done
    ${DAEMON_NAME} config node tcp://localhost:${port_prefix}657
    sed -i.bak -e "s%:1317%:${port_prefix}317%g; s%:8080%:${port_prefix}080%g; s%:9090%:${port_prefix}090%g; s%:9091%:${port_prefix}091%g; s%:8545%:${port_prefix}545%g; s%:8546%:${port_prefix}546%g; s%:6065%:${port_prefix}065%g" ${DAEMON_HOME}/config/app.toml
    sed -i.bak -e "s%:26658%:${port_prefix}658%g; s%:26657%:${port_prefix}657%g; s%:6060%:${port_prefix}060%g; s%:26656%:${port_prefix}656%g; s%:26660%:${port_prefix}660%g" ${DAEMON_HOME}/config/config.toml
    ${DAEMON_NAME} config node tcp://localhost:${port_prefix}657
fi

#Set configs
wget ${GENESIS_URL} -O ${DAEMON_HOME}/config/genesis.json
sed -i.bak \
    -e "/^[[:space:]]*seeds =/ s/=.*/= \"${SEEDS}\"/" \
    -e "s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"${PEERS}\"/" \
    ${DAEMON_HOME}/config/config.toml

sed -i 's/minimum-gas-prices *=.*/minimum-gas-prices = "0'$DENOM'"/' ${DAEMON_HOME}/config/app.toml
sed -i \
    -e 's|^[[:space:]]*pruning *=.*|pruning = "custom"|' \
    -e 's|^[[:space:]]*pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
    -e 's|^[[:space:]]*pruning-keep-every *=.*|pruning-keep-every = "0"|' \
    -e 's|^[[:space:]]*pruning-interval *=.*|pruning-interval = "10"|' \
    ${DAEMON_HOME}/config/app.toml
indexer="null" && \
sed -i -e "s/^[[:space:]]*indexer *=.*/indexer = \"$indexer\"/" ${DAEMON_HOME}/config/config.toml

WALLET_ADDRESS=$(${DAEMON_NAME} keys show $VALIDATOR_KEY_NAME -a)
VALOPER_ADDRESS=$(${DAEMON_NAME} keys show $VALIDATOR_KEY_NAME --bech val -a)

# Helper scripts
cd ${INSTALLATION_DIR}
rm -rf list_keys.sh check_balance.sh create_validator.sh unjail_validator.sh check_validator.sh start_side.sh check_log.sh

echo "${DAEMON_NAME} keys list" > list_keys.sh
chmod ug+x list_keys.sh

echo "${DAEMON_NAME} q bank balances ${WALLET_ADDRESS}" > check_balance.sh
chmod ug+x check_balance.sh

tee claim_commission.sh > /dev/null <<EOF
#!/bin/bash
${DAEMON_NAME} tx distribution withdraw-rewards ${VALOPER_ADDRESS} \\
  --from=$VALIDATOR_KEY_NAME \\
  --commission \\
  --chain-id="$CHAIN_ID" \\
  --fees="1000${DENOM}" \\
  --yes
${DAEMON_NAME} tx distribution withdraw-all-rewards \\
  --from=$VALIDATOR_KEY_NAME \\
  --commission \\
  --chain-id="$CHAIN_ID" \\
  --fees="1000${DENOM}" \\
  --yes
EOF
chmod ug+x claim_commission.sh

tee delegate.sh > /dev/null <<EOF
#!/bin/bash
${DAEMON_NAME} q bank balances ${WALLET_ADDRESS}

while true; do
    read -p "Enter the amount to delegate (in $DENOM, not 0): " amount
    if [[ ! \${amount} =~ ^[0-9]+(\.[0-9]*)?$ ]] || (( 10#\${amount} == 0 )); then
        echo "Invalid amount, please try again" >&2
    else
        ${DAEMON_NAME} tx staking delegate ${VALOPER_ADDRESS} \${amount}${DENOM} \\
        --from=$VALIDATOR_KEY_NAME \\
        --chain-id="$CHAIN_ID" \\
        --gas="200000" \\
        --gas-prices="0.025${DENOM}"
    fi
done
EOF
chmod ug+x delegate.sh

if [ "$VALIDATOR_CREATE_TYPE" == "json" ]; then
    tee create_validator.sh > /dev/null <<EOF
${DAEMON_NAME} tx staking create-validator ./validator.json \\
  --from=${VALIDATOR_KEY_NAME} \\
  --chain-id=${CHAIN_ID} \\
  --fees=500${DENOM}
EOF

    tee validator.json > /dev/null <<EOF
{
  "pubkey": $(${DAEMON_NAME} comet show-validator),
  "amount": "1000000${DENOM}",
  "moniker": "$VALIDATOR_KEY_NAME",
  "identity": "$INPUT_IDENTITY",
  "website": "$INPUT_WEBSITE",
  "security": "$INPUT_EMAIL",
  "details": "$INPUT_DETAILS",
  "commission-rate": "0.1",
  "commission-max-rate": "0.2",
  "commission-max-change-rate": "0.01",
  "min-self-delegation": "1"
}
EOF
else
    tee create_validator.sh > /dev/null <<EOF
${DAEMON_NAME} tx staking create-validator \\
  --amount=100000${DENOM} \\
  --pubkey=\$(${DAEMON_NAME} tendermint show-validator) \\
  --moniker=${VALIDATOR_KEY_NAME} \\
  --identity=${INPUT_IDENTITY} \\
  --website=${INPUT_WEBSITE} \\
  --security-contact=${INPUT_EMAIL} \\
  --details=${INPUT_DETAILS} \\
  --chain-id=${CHAIN_ID} \\
  --commission-rate="0.05" \\
  --commission-max-rate="0.20" \\
  --commission-max-change-rate="0.01" \\
  --min-self-delegation="10000" \\
  --gas "auto" \\
  --gas-adjustment "1.5" \\
  --fees "800${DENOM}" \\
  --from=${VALIDATOR_KEY_NAME}
EOF
fi
chmod ug+x create_validator.sh

tee unjail_validator.sh > /dev/null <<EOF
#!/bin/bash
${DAEMON_NAME} tx slashing unjail \\
 --from=$VALIDATOR_KEY_NAME \\
 --chain-id="$CHAIN_ID" \\
 --gas="300000" \\
 --gas-prices="0.025${DENOM}"
EOF
chmod ug+x unjail_validator.sh

tee check_validator.sh > /dev/null <<EOF
#!/bin/bash
${DAEMON_NAME} query tendermint-validator-set | grep "$(${DAEMON_NAME} tendermint show-address)"
EOF
chmod ug+x check_validator.sh

tee state_sync.sh > /dev/null <<EOF
#!/bin/bash
SNAP_RPC=${SNAP_RPC}
sudo systemctl stop ${SERVICE_NAME}
mv ${DAEMON_HOME}/data/priv_validator_state.json ${DAEMON_HOME}/priv_validator_state.json.backup
${DAEMON_NAME} tendermint unsafe-reset-all --keep-addr-book --home ${DAEMON_HOME}
LATEST_HEIGHT=\$(curl -s \$SNAP_RPC/block | jq -r .result.block.header.height);
LATEST_HEIGHT=\$(echo "\$LATEST_HEIGHT" | awk '{printf "%d000\n", \$0 / 1000}')
BLOCK_HEIGHT=\$((LATEST_HEIGHT - 1000));
TRUST_HASH=\$(curl -s "\$SNAP_RPC/block?height=\$BLOCK_HEIGHT" | jq -r .result.block_id.hash)
echo \$LATEST_HEIGHT \$BLOCK_HEIGHT \$TRUST_HASH
sed -i \\
    -e "s|^.*enable *=.*|enable = "true"|" \\
    -e "s|^.*rpc_servers *=.*|rpc_servers = \\"\$SNAP_RPC,\$SNAP_RPC\\"|" \\
    -e "s|^.*trust_height *=.*|trust_height = \$BLOCK_HEIGHT|" \\
    -e "s|^.*trust_hash *=.*|trust_hash = \\"\$TRUST_HASH\\"|" \\
    ${DAEMON_HOME}/config/config.toml
mv ${DAEMON_HOME}/priv_validator_state.json.backup ${DAEMON_HOME}/data/priv_validator_state.json
sudo systemctl start ${SERVICE_NAME}
EOF
chmod ug+x state_sync.sh

tee start_${DAEMON_NAME}.sh > /dev/null <<EOF
sudo systemctl daemon-reload
sudo systemctl enable ${SERVICE_NAME}
sudo systemctl restart ${SERVICE_NAME}
EOF
chmod ug+x start_${DAEMON_NAME}.sh

tee stop_${DAEMON_NAME}.sh > /dev/null <<EOF
sudo systemctl stop ${SERVICE_NAME}
EOF
chmod ug+x stop_${DAEMON_NAME}.sh

tee check_log.sh > /dev/null <<EOF
sudo journalctl -u ${SERVICE_NAME} -f
EOF
chmod ug+x check_log.sh

sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null <<EOF
[Unit]
Description=${DAEMON_NAME} daemon
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) run start
Restart=always
RestartSec=3
LimitNOFILE=infinity

Environment="DAEMON_NAME=${DAEMON_NAME}"
Environment="DAEMON_HOME=${DAEMON_HOME}"
Environment="DAEMON_RESTART_AFTER_UPGRADE=false"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable ${SERVICE_NAME}.service
read -p "Do you want to enable the State Sync? (y/N): " ENABLE_STATE_SYNC
if [[ "$ENABLE_STATE_SYNC" =~ ^[Yy](es)?$ ]]; then
    echo "Enabling State Sync..."
    ${DAEMON_NAME} tendermint unsafe-reset-all --keep-addr-book --home ${DAEMON_HOME}
    LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height);
    LATEST_HEIGHT=$(echo "$LATEST_HEIGHT" | awk '{printf "%d000\n", $0 / 1000}')
    BLOCK_HEIGHT=$((LATEST_HEIGHT - 1000));
    TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)
    echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH
    sed -i \
        -e "s|^.*enable *=.*|enable = "true"|" \
        -e "s|^.*rpc_servers *=.*|rpc_servers = \"$SNAP_RPC,$SNAP_RPC\"|" \
        -e "s|^.*trust_height *=.*|trust_height = $BLOCK_HEIGHT|" \
        -e "s|^.*trust_hash *=.*|trust_hash = \"$TRUST_HASH\"|" \
        ${DAEMON_HOME}/config/config.toml
    echo "State Sync Enabled!"
else
    echo "Skipping enabling State Sync."
fi
read -p "Do you want to start the ${SERVICE_NAME} service? (y/N): " START_SERVICE
if [[ "$START_SERVICE" =~ ^[Yy](es)?$ ]]; then
    sudo systemctl start ${SERVICE_NAME}.service
else
    echo "Skipping starting ${SERVICE_NAME} service."
fi
