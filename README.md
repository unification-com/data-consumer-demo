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

## Deploying

### 1. Install dependencies

Clone this repo:

```bash 
git clone https://github.com/unification-com/data-consumer-demo
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

### 3. Set up `.env`

Copy the `example.env` to `.env` and edit the variables, adding the address and private
key for the **wallet you intend to use to deploy the smart contract**.

The required deployed contract addresses are as follows:

#### Testnet (Rinkeby)

`ROUTER_ADDRESS=0x3c0973B8Bf9bCafaa5e748aC2617b1C19b15dD8B`  
`CONSUMER_LIB_ADDRESS=0xD64127b18F8280F0528Cf5b77402a358cC21612E`  

The `xFUNDMOCK` Token is at `0x81366aF400cf3050eA04B1BcB8592C3203C84dFb` (required to 
fund any test accounts)

Finchains Data Provider Oracle: `0x611661f4B5D82079E924AcE2A6D113fAbd214b14`

### 4. Deploy

Grab some test ETH from the [Rinkeby faucet](https://faucet.rinkeby.io/) for the wallet
address defined in your `.env`, and deploy the smart contract on Rinkeby testnet:

```bash 
npx truffle deploy --network=rinkeby
```

#### 4.1 Optional - upload and verify contract code to Etherscan

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

Within the `truffle` console, load the contract instances, and accounts
ready for interaction

```bash 
truffle(rinkeby)> let accounts = await web3.eth.getAccounts()
truffle(rinkeby)> let consumerOwner = accounts[0]
truffle(rinkeby)> let provider = "0x611661f4B5D82079E924AcE2A6D113fAbd214b14"
truffle(rinkeby)> let demoConsumer = await DemoConsumer.deployed()
```

### Initialising

The following steps need only be done periodically, to ensure all parties have
the correct amount of tokens and gas to pay for data.

Go to [xFUNDMOCK](https://rinkeby.etherscan.io/address/0x81366aF400cf3050eA04B1BcB8592C3203C84dFb#writeContract)
on Etherscan, and connect MetaMask **with the account used to deploy the `DemoConsumer`
smart contract**, then run the `gimme()` function. This is a faucet function, and will
supply your wallet with 10 `xFUNDMOCK` tokens. You may do this once per hour.

Get the deployed address for your `DemoConsumer` smart contract:

```bash 
truffle(rinkeby)> demoConsumer.address
```

Next, using either Etherscan, or MetaMask, transfer 5 `xFUNDMOCK` tokens to your
`DemoConsumer` contract address.

Then we need to allow the `Router` smart contract to pay fees on the `DemoConsumer` contract's
behalf:

```bash 
truffle(rinkeby)> demoConsumer.setRouterAllowance("115792089237316195423570985008687907853269984665640564039457584007913129639935", true, {from: consumerOwner})
```

Next, we need to authorise a data provider (in this case `0x611661f4B5D82079E924AcE2A6D113fAbd214b14`)
to supply our `DemoConsumer` smart contract with data. Only authorised provider addresses
can send transactions to supply your contract with data.

```bash 
truffle(rinkeby)> demoConsumer.addRemoveDataProvider(provider, 100000000, false, {from: consumerOwner})
```

This will authorise `0x611661f4B5D82079E924AcE2A6D113fAbd214b14` to send data to your
smart contract, and set their fee to 0.1 `xFUNDMOCK` tokens per request.

Finally, we need top up gas allowance on the `Router` smart contract. This will send 
a small amount of ETH to the the `Router` smart contract, allowing it to refund any 
gas the provider spends sending data to your `MockConsumer` contract. It will be 
assigned to the provider's wallet, and can be fully withdrawn at any time. The
source of the ETH is the `DemoConsumer` contract owner (the wallet that deployed the 
contract). Run:

```bash
truffle(rinkeby)> demoConsumer.topUpGas(provider, {from: consumerOwner, value: 500000000000000000})
```

This will send 0.5 ETH (the maximum that the Router will accept in any one transaction),
and lock it to the authorised Provider's address.

ETH held by the `Router` will only ever be used to reimburse the specified and 
authorised provider's wallet address.

### Requesting Data

Now that the `DemoConsumer` smart contract is fully initialised, and we have set up the
authorised data provider and respective payment flows, we can request data to be sent to
the smart contract. You will need to top up the Router's gas, and Consumer contract's 
tokens every so often.

First, check the current `price` in your `DemoConsumer` contract. Run:

```bash
truffle(rinkeby)> let priceBefore = await demoConsumer.price()
truffle(rinkeby)> priceBefore.toString()
```

The result should be 0.

Next, request some data from the provider. Run:

```bash
truffle(rinkeby)> let endpoint = web3.utils.asciiToHex("BTC.USD.PR.AVI")
truffle(rinkeby)> demoConsumer.requestData(provider, endpoint, 80, {from: consumerOwner})
```

The first command encodes the data endpoint (the data we want to get) into a bytes32
value. We are requesting the mean US dollar (`USD`) price of Bitcoin (`BTC`), with 
outliers (very high or very low) values removed (`PR.AVI`) from the final mean calculation.

A full list of supported currency pairs is available from the [Finchains API](https://crypto.finchains.io/api/pairs)

It may take a block or two for the request to be fully processed - the provider will listen for
the request, then submit a Tx with the data to the `Router`, which will forward it to
your smart contract.

After 30 seconds or so, run:

```bash
truffle(rinkeby)> let priceAfter = await demoConsumer.price()
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
