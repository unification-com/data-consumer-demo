require("dotenv").config()
const DemoConsumer = artifacts.require("DemoConsumer")
const { abi } = require("./abi/xfund_mock")

const { ROUTER_ADDRESS, XFUND_ADDRESS } = process.env

module.exports = async function(callback) {
  const network = config.network
  const demoConsumer = await DemoConsumer.deployed()
  const accounts = await web3.eth.getAccounts()
  const consumerOwner = accounts[0]

  try {
    let tx
    const xfund = await new web3.eth.Contract(abi, XFUND_ADDRESS)
    switch(network) {
      case 'development':
      case 'develop':
      case 'goerli':
      case 'mainnet':
        console.log("gimme")
        tx = await xfund.methods.gimme().send({from: consumerOwner})
        console.log(tx)
        break
    }

    const demoConsumerBalance = await xfund.methods.balanceOf(demoConsumer.address).call()

    console.log(`DemoConsumer balance: ${demoConsumerBalance}`)

    if(demoConsumerBalance === "0") {
      console.log("transfer xfund")
      tx = await xfund.methods.transfer(demoConsumer.address, "1000000000").send( {from: consumerOwner})
      console.log(tx)
    }

    const routerAllowance = await xfund.methods.allowance(demoConsumer.address, ROUTER_ADDRESS).call()

    console.log(`Router allowance: ${routerAllowance}`)

    if(routerAllowance === "0") {
      console.log("increase router allowance")
      tx = await demoConsumer.increaseRouterAllowance("115792089237316195423570985008687907853269984665640564039457584007913129639935", {from: consumerOwner})
      console.log(tx)
    }

    callback()
  } catch (error) {
    console.log(error)
    callback()
  }

  callback()
}
