# Quicksilver Mainnet joining instructions

Genesis Transaction Submissions have closed.

## Minimum hardware requirements

- 4 cores (max. clock speed possible)
- 16GB RAM
- 500GB+ of NVMe or SSD disk

## Software requirements

### Install Quicksilver

Requires [Go version v1.19+](https://golang.org/doc/install).

  ```sh
  > git clone https://github.com/ingenuity-build/quicksilver && cd quicksilver
  > git fetch origin --tags
  > git checkout v1.0.0
  > make install
  ```
  
binary file will be made on following path `quicksilver/build`

#### Verify installation

To verify if the installation was successful, execute the following command:

  ```sh
  > quicksilverd version --long
  ```

It will display the version of quicksilverd currently installed:

  ```sh
  name: quicksilver
  server_name: quicksilverd
  version: 1.0.0
  commit: 6371729e38fe8f55c02c9d550107f4618c130c89
  build_tags: netgo,ledger,musl
  go: go version go1.19.4 linux/amd64
  ```

## Create a validator

1. Init Chain and start your node

   ```sh
   > quicksilverd init <moniker-name> --chain-id=quicksilver-1
   ```

2. Create a local key pair
  **Note: we recommend _only_ using Ledger for mainnet! Key security is important!**

   ```sh
   > ## create a new key:
   > quicksilverd keys add <key-name>
   > ## or use a ledger:
   > quicksilverd key add <key-name> --ledger     
   > ## or import an old key:
   > quicksilverd keys show <key-name> -a
   ```

3. Download genesis
   Fetch `genesis.json` into `quicksilverd`'s `config` directory (default: ~/.quicksilverd)

   ```sh
   > curl -s https://raw.githubusercontent.com/ingenuity-build/mainnet/main/genesis.json > genesis.json
   ```

   **Genesis sha256**

   ```sh
    jq . -S -c ~/.quicksilverd/config/genesis.json | shasum -a 256 
    8bfc3aa7a81eb8c1a2452bdb8d256b372ecfdd67c634b4f63846f755ef4dd815  /home/<user>/.quicksilverd/config/genesis.json
   ```

4. Define minimum gas prices
    ```sh
    sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.0001uqck\"/;" ~/.quicksilverd/config/app.toml
    ```

5. Define seed nodes
    ```sh
    export SEEDS="20e1000e88125698264454a884812746c2eb4807@seeds.lavenderfive.com:11156,babc3f3f7804933265ec9c40ad94f4da8e9e0017@seed.rhinostake.com:11156,00f51227c4d5d977ad7174f1c0cea89082016ba2@seed-quick-mainnet.moonshot.army:26650"
    sed -i.bak -e "s/^seeds *=.*/seeds = \"$SEEDS\"/" ~/.quicksilverd/config/config.toml
    ```

6. Start your node and sync to the latest block

7. Create validator

   ```sh
   $ quicksilverd tx staking create-validator \
   --amount 50000000uqck \
   --commission-max-change-rate "0.1" \
   --commission-max-rate "0.20" \
   --commission-rate "0.1" \
   --min-self-delegation "1" \
   --details "a short description lives here" \
   --pubkey=$(quicksilverd tendermint show-validator) \
   --security-contact "youremail@goes.here" \
   --moniker <your_moniker> \
   --chain-id quicksilver-1 \
   --from <key-name>
   ```

## Cosmovisor

Optional, but highly recommended for upgrade automation.

Cosmovisor is process manager for Cosmos-SDK application binaries that enables node automation. It monitors the application's governance module for upgrade proposals and allows for automation of application binary downloads and replacement, resulting in near zero-downtime chain upgrades.

### Installation

#### 1. Install cosmovisor

Using go version 1.15 or later:

```
go install github.com/cosmos/cosmos-sdk/cosmovisor/cmd/cosmovisor@latest
```

or, specify the target version, for example:

```
go install github.com/cosmos/cosmos-sdk/cosmovisor/cmd/cosmovisor@v1.0.0
```

Confirm installation with:

```
which cosmovisor
```

The output should be a path to the cosmovisor binary:

```
/home/<user>/go/bin/cosmovisor
```

#### 2. Add environment variables to shell

The following environment variables must be set:

1. `export DAEMON_NAME=quicksilverd`
2. `export DAEMON_HOME=$HOME/.quicksilverd`
3. `export DAEMON_DATA_BACKUP_DIR=$HOME/.quicksilverd/data_backup`

Ensure your environment setup is correctly configured to persist across sessions. Make use of the appropriate system environment configuration files, such as `.profile` to accomplish this.

#### 3. Directory structure

Cosmovisor expects the following directory structure in `$DAEMON_HOME/cosmovisor`:

```
.
├── current -> genesis or upgrades/<name>
├── genesis
│   └── bin
│       └── $DAEMON_NAME
└── upgrades
    └── <name>
        └── bin
            └── $DAEMON_NAME
```

Create the target directory structure with the following:

```
mkdir -p $DAEMON_HOME/cosmovisor/genesis/bin
mkdir -p $DAEMON_HOME/cosmovisor/upgrades
```

`current` is a symlink that will be created by `cosmovisor`.

### Set the genesis binary

Cosmovisor requires the genesis binary to be set. Do this by copying the quicksilverd binary to `$DAEMON_HOME/cosmovisor/genesis/bin/$DAEMON_NAME`.

```
# find quicksilverd binary
which quicksilverd

# copy binary to cosmovisor genesis using output from above command, e.g.
cp build/quicksilverd $DAEMON_HOME/cosmovisor/genesis/bin/$DAEMON_NAME
```

### Configure cosmovisor as a system service

Create the system service file:

```
sudo touch /etc/systemd/system/cosmovisor.service
```

Use an editor like `vim`, `micro` or `nano` and set the contents of the file according to your system configuration, for example:

```
[Unit]
Description=cosmovisor
After=network-online.target

[Service]
User=<your-user>
ExecStart=/home/<your-user>/go/bin/cosmovisor start
Restart=always
RestartSec=3
LimitNOFILE=4096
Environment="DAEMON_NAME=quicksilverd"
Environment="DAEMON_HOME=/home/<your-user>/.quicksilverd"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=false"
# Set buffer size to handle:
# https://github.com/cosmos/cosmos-sdk/pull/8590
Environment="DAEMON_LOG_BUFFER_SIZE=512"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="DAEMON_POLL_INTERVAL=300ms"
Environment="DAEMON_DATA_BACKUP_DIR=${HOME}/.quicksilverd"
# Set to true if disk space is limited:
Environment="UNSAFE_SKIP_BACKUP=false"
Environment="DAEMON_PREUPGRADE_MAX_RETRIES=0"

[Install]
WantedBy=multi-user.target
```

**IMPORTANT**: If you have limited disk space please set `UNSAFE_SKIP_BACKUP=true`. This will avoid an upgrade failure due to insufficient disk space when the backup is created.

Enable and start the cosmovisor service:

```
sudo systemctl daemon-reload
sudo systemctl enable cosmovisor
sudo systemctl restart cosmovisor
```

Check that the service is running:

```
sudo systemctl status cosmovisor
```
