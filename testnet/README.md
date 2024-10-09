# Quicksilver Testnets

All Quicksilver testnets have been and will continue to be named after songs by Freddie Mercury and/or Queen, for no reason more than the guy was a lyrical and musical genius, and there is a somewhat tenuous link between Quicksilver -> Mercury -> Freddie that is ripe for exploitation.

![Freddie Mercury](https://static.miraheze.org/nonciclopediawiki/thumb/8/84/Freddie_Mercury_simpson.png/200px-Freddie_Mercury_simpson.png)

# Rhye-3

The third installment of the "Rhye" long-running testnet is here.

Rhye-2 halted due to loss of hardware when migrating Quicksilver between Notional and Somatic Lab. It was decided to relaunch the testnet as `rhye-3`.

Rhye-3 is a clean launch, with entirely new state.

In order to onboard your new `rhye-3`, you must do the following:

1. Build, or download the Quicksilver v1.6.3 binary from https://github.com/quicksilver-zone/quicksilver; alternatively use the docker container at quicksilverzone/quicksilver:v1.6.3.
2. Run `quicksilverd init <moniker>`.
3. Download the genesis file in the rhye-3 folder to ~/.quicksilverd/config/genesis.json.
4. Assert the genesis file you downloaded matches the expected hash, using `cat ~/.quicksilverd/config/genesis.json | jq . -Sc | shasum -a256`. It should return `e0cd0640a2a6e30667d1e3393e958f8333736c44799a64857a7c90e2dc11dd03`.
5. Start the process with `quicksilverd start`. You will probably want to run this as a service.
6. Once synced (check https://rhye-3.rpc.quicksilver.zone/status), you will want to create a key, get some funds from the faucet, and create your validator:

#### Create a key

```sh
$ quicksilverd keys add <key>
```

For example:

```sh
$ quicksilverd keys add testkey

- address: quick14xcgnfvmd9xzu5em2gr5d0ykepv4m0y4f4z8lk
  name: testkey
  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"AvE1BMXRvtydR95jRdrGzWOVpmlC1Uf6V5SazxxFTECa"}'
  type: local


**Important** write this mnemonic phrase in a safe place.
It is the only way to recover your account if you ever forget your password.

random spoil vivid negative wedding moon blast own oxygen fish border project cabbage agent belt dress body absent book tiny myself reflect minimum supreme
```

#### Obtain funds

TBC.

#### Create a validator

```sh
$ quicksilverd tx staking create-validator \
--from <key> \
--amount 100000000000uqck \
--chain-id="rhye-3" \
--commission-rate="<commission>" \
--commission-max-rate="<max-commission>" \
--commission-max-change-rate="<max-commission-rate-change>" \
--min-self-delegation="<min-self-delegation>" \
```

## Peers and Seeds

Peers and Seeds can be found [here](./rhye-3/PEERS.md). Please add your nodes to this list through a PR.

## Docs

Found anything missing or inaccurate? [Create an issue](https://github.com/quicksilver-zone/networks/issues) or make a pull request!
