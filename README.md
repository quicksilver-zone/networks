# Quicksilver-2 chain restart instructions

Chain restart is due at 1500 UTC on Tuesday 3rd January 2023. We will use `quicksilverd v1.2.0` to export and restart the chain. You must upgrade before the export, else the export will fail. For build instructions, see below.

1. `git fetch && git checkout v1.2.0`
1. `make install`
1. `quicksilverd export --for-zero-height --height 115000 > export-quicksilver-1-115000.json`
1. `jq . export-quicksilver-1-115000.json -S -c | shasum -a256`
1. Check output matches `7df73ba5fdbaf6f4b5cced3f16b8f44047ad8f42a7a6f87f764413b474e81c54`
1. Run `python3 migrate-genesis.py`
1. `jq . genesis.json -S -c | shasum -a256`
1. Check output matches `df8e9b87c7495e8a62932c8660724dd906255b0ec9ee5094cfcb860fc0115ec1`
1. `cp genesis.json ~/.quicksilverd/config/genesis.json` (be sure to replace `~/.quicksilverd` with your node's `HOME`).
1. `quicksilverd tendermint unsafe-reset-all`
1. If you use an external signer, update the chain_id and reset state.
1. `quicksilverd start` or, if using systemd, `systemctl start quicksilver`

# Quicksilver Mainnet joining instructions

## Minimum hardware requirements

- 4 cores (max. clock speed possible)
- 16GB RAM
- 500GB+ of NVMe or SSD disk

## Software requirements

Current version: v1.2.0

### Install Quicksilver

Requires [Go version v1.19+](https://golang.org/doc/install).

```sh
> git clone https://github.com/ingenuity-build/quicksilver && cd quicksilver
> git fetch origin --tags
> git checkout v1.2.0
> make install
or
> make build
```

`make build` will output the binary in the `build` directory.

Alternatively, to build a docker container, use `make build-docker`.

#### Verify installation

To verify if the installation was successful, execute the following command:

```sh
> quicksilverd version --long
```

It will display the version of quicksilverd currently installed:

```sh
name: quicksilverd
server_name: quicksilverd
version: 1.2.0
commit: 0ce6daf33aaeb93e1cb306a1fc8672c0123cffd1
build_tags: netgo,ledger
go: go version go1.19.2 linux/amd64
```

**Ensure go version is 1.19+; using 1.18 will cause non-deterministic behaviour.**

## Create a validator

1. Init Chain and start your node

   ```sh
   > quicksilverd init <moniker-name> --chain-id=quicksilver-2
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
    shasum -a 256 ~/.quicksilverd/config/genesis.json
    df8e9b87c7495e8a62932c8660724dd906255b0ec9ee5094cfcb860fc0115ec1  /home/<user>/.quicksilverd/config/genesis.json
   ```

4. Start your node and sync to the latest block

5. Create validator

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
   --chain-id quicksilver-2 \
   --from <key-name>
   ```
