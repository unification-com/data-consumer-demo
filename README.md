# Data Consumer Demo

This repo contains a couple of simple implementations of a demo Consumer smart contract, which 
implements the [xFUND Router & Data Provision](https://github.com/unification-com/xfund-router)
suite.

It contains everything required to get started, including a skeleton, simple smart contract
([DemoConsumer.sol](contracts/DemoConsumer.sol)) which can be modified, deployed and tested.

Additionally, [DemoConsumerCustom.sol](contracts/DemoConsumerCustom.sol) contains
more sophisticated custom data request and receive functions to give an example of
how the base contract can be extended to suite your needs.

The interaction guide below focuses on the simpler `DemoConsumer` smart contract, but
both are deployed during the process, and can be interacted with.

## Custom networks

Copy the `custom_networks.example.js` to `custom_networks.js` and modify as required. It will then be possible to
pass the network using the `--network` flag with any `truffle` command.

## Deploying

### 1. Install dependencies

Open a Terminal and clone this repo:

```bash 
git clone https://github.com/unification-com/data-consumer-demo
cd data-consumer-demo
```

`NodeJS` is required to use this software. We recommend using 
[nvm](https://github.com/nvm-sh/nvm) to manage NodeJS installations, and currently.
recommend NodeJS v12.18.3.

We also recommend [Yarn](https://classic.yarnpkg.com/en/docs/install) for `npm`
package management.

Install the dependencies with either `yarn`

```bash 
yarn install
```

or `npm`

```bash 
npm install
```

### 2. Compile the contracts

Compile the contracts using `truffle`:

```bash 
npx truffle compile
```

### 3. Get some Test ETH for the Rinkeby Network

Using Metamask, or similar Wallet manager create a new wallet address (or use an existing one).

Grab some test ETH from the [Rinkeby faucet](https://faucet.rinkeby.io/) for this wallet address.

You will also need to make a note of the **Private Key** and **Wallet address** for the next 
steps.

This wallet will be used to deploy the smart contract, and interact with it.

### 4. Set up `.env`

Copy the `example.env` to `.env`:

```bash
cp example.env .env
```

Open the new `.env` file in a text editor and edit the variables, adding the private
key for the **wallet you intend to use to deploy the smart contract** (the one from step 3)
for the `ETH_PKEY` variable. You aill also need an [Infura])(https://infura.io) API key,
and _optionally_ an [Etherscan](https://etherscan.io/apis) API key.

The **Rinkeby** values for `ROUTER_ADDRESS` and `XFUND_ADDRESS` can be found at
[https://docs.finchains.io/contracts.html](https://docs.finchains.io/contracts.html).

The **Rinkeby** values for `PROVIDER_ADDRESS` and `FEE` can be found at
[https://docs.finchains.io/guide/ooo_api.html](https://docs.finchains.io/guide/ooo_api.html).

At the date of commit, these values are:

```
ROUTER_ADDRESS=0x05AB63BeC9CfC3897a20dE62f5f812de10301FDf
XFUND_ADDRESS=0x245330351344F9301690D5D8De2A07f5F32e1149
PROVIDER_ADDRESS=0x611661f4B5D82079E924AcE2A6D113fAbd214b14
FEE=100000000
```

### 5. Deploy

Once your `.env` is configured, deploy the smart contract on Rinkeby testnet:

```bash 
npx truffle deploy --network=rinkeby
```

#### 5.1 Optional - upload and verify contract code to Etherscan

Optionally, you can upload the source code and verify the contract on Etherscan, so that
you can interact with it via Etherscan. You will need an 
[Etherscan API key](https://etherscan.io/apis), and to add the value to your `.env`
by setting the `ETHERSCAN_API` value. Once that's done, run:

```bash
npx truffle run verify DemoConsumer --network=rinkeby
npx truffle run verify DemoConsumerCustom --network=rinkeby
```

## Interacting

**Note**: Both demo contracts `DemoConsumer.sol` and `DemoConsumerCustom.sol` should now have been
deployed. The following interaction overview covers the simpler `DemoConsumer` smart
contract. With the exceptions of calling the `requestData` and getting the price data from
`DemoConsumer` contract, the following steps are the same for both demo contracts.

See the `customRequestData` and `getPrice` functions in the 
[DemoConsumerCustom.sol](contracts/DemoConsumerCustom.sol) contract
for examples on how to interact with the customised version.

Run the `truffle` development console, and connect to the Rinkeby testnet:

```bash
npx truffle console --network=rinkeby
```

### Initialising

The following steps need only be done periodically, to ensure all parties have
the correct amount of tokens and gas to pay for data.

Go to [xFUNDMOCK](https://rinkeby.etherscan.io/address/0x245330351344F9301690D5D8De2A07f5F32e1149#writeContract)
on Etherscan, and connect MetaMask **with the account used to deploy the `DemoConsumer`
smart contract**, then run the `gimme()` function. This is a faucet function, and will
supply your wallet with 10 `xFUNDMOCK` tokens. You may do this once per hour.

Within the `truffle` console, load the contract instances, and set some variables
ready for interaction

```bash 
truffle(rinkeby)> let provider = process.env.PROVIDER_ADDRESS
truffle(rinkeby)> let demoConsumer = await DemoConsumer.deployed()
```

Get the deployed address for your `DemoConsumer` smart contract:

```bash 
truffle(rinkeby)> demoConsumer.address
```

Next, using either Etherscan, or MetaMask, transfer 5 `xFUNDMOCK` tokens to your
`DemoConsumer` contract address.

Wait for the transaction to succeed, then get the current account information

```bash
truffle(rinkeby)> let accounts = await web3.eth.getAccounts()
truffle(rinkeby)> let consumerOwner = accounts[0]
```

Then we need to allow the `Router` smart contract to pay fees on the `DemoConsumer` contract's
behalf:

```bash 
truffle(rinkeby)> demoConsumer.increaseRouterAllowance("115792089237316195423570985008687907853269984665640564039457584007913129639935", {from: consumerOwner})
```

### Requesting Data

Now that the `DemoConsumer` smart contract is fully initialised, we can request data 
to be sent to the smart contract. You will need to top up the Consumer contract's 
tokens every so often.

First, check the current `price` in your `DemoConsumer` contract. Run:

```bash
truffle(rinkeby)> let priceBefore = await demoConsumer.getPrice()
truffle(rinkeby)> priceBefore.toString()
```

The result should be 0.

Next, request some data from the provider. Run:

```bash
truffle(rinkeby)> let endpoint = web3.utils.asciiToHex("BTC.GBP.PR.AVC.24H")
truffle(rinkeby)> demoConsumer.requestData(endpoint, {from: consumerOwner})
```

The first command encodes the data endpoint (the data we want to get) into a bytes32
value. We are requesting the mean US dollar (`USD`) price of Bitcoin (`BTC`), with 
outliers (very high or very low) values removed (`PR.AVI`) from the final mean calculation.

A full list of supported API endpoints is available from the 
[Finchains OoO API Docs](https://docs.finchains.io/guide/ooo_api.html)

It may take a block or two for the request to be fully processed - the provider will listen for
the request, then submit a Tx with the data to the `Router`, which will forward it to
your smart contract.

After 30 seconds or so, run:

```bash
truffle(rinkeby)> let priceAfter = await demoConsumer.getPrice()
truffle(rinkeby)> priceAfter.toString()
```

If the price is still 0, simply run the following a couple more times:

```bash
truffle(rinkeby)> priceAfter = await demoConsumer.price()
truffle(rinkeby)> priceAfter.toString()
```

The price should now be a non-zero value.

To convert to the actual price:

```bash
truffle(rinkeby)> let realPrice = web3.utils.fromWei(priceAfter)
truffle(rinkeby)> realPrice.toString()
```

**Note**: the Oracle sends all price data converted to `actualPrice * (10 ** 18)` in
order to remove any decimals.

## Helper scripts

There are a couple of helper scripts in `dev_scripts` which can be run via Truffle
to automate requesting and cancelling data requests on Rinkeby Testnet for your contract.

Request data and check fulfilment with:

```bash
npx truffle exec dev_scripts/request-data.js --network=rinkeby
```
