# Quicksilver Mainnet joining instructions

**If you have not yet installed Quicksilver, follow the instructions [here](README.md)**

## Create a genesis validator

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

3. Add genesis account

  ```sh
  > quicksilverd add-genesis-account 51000000uqck
  ```

4. Create gentx file
  Use the flags here to set commission rate, self bonds and descriptions and so on.

  ```sh
  > quicksilverd gentx <key> 50000000uqck --moniker <moniker> --chain-id quicksilver-1
  ```

5. Upload gentx.json
  Copy the contents of the above command into a commit at `https://github.com/ingenuity-build/mainnet` in the `gentxs` folder. Name the file with your validator moniker (figment.json, witval.json, etc.) so we can contact you in the event of a problem. If your gentx is invalid and your file is not appropriately named you may miss out on genesis!

### Launch day

1. Check to see if there has been a later release. 
  If we have had to push any last minute tweaks, ensure you have the latest version of the codebase.

2. Download genesis 
  Fetch genesis.json into quicksilverd's config directory (default: `~/.quicksilverd`). It shall be released 24h before the network starts.

  ```sh
  > curl -s https://raw.githubusercontent.com/ingenuity-build/mainnet/main/genesis/genesis.tar.gz > genesis.tar.gz
  > tar -C ~/.quicksilverd/config/ -xvf genesis.tar.gz
   ```
3. Check genesis

  ```sh
  > shasum -a 256 ~/.quicksilverd/config/genesis.json
  XXX  /home/<user>/.quicksilverd/config/genesis.json
  ```

4. Start your node and get ready to play!
