const { abi } = require( "./abi/xfund_mock" )
require("dotenv").config()
const DemoConsumer = artifacts.require("DemoConsumer")

const { ROUTER_ABI, ROUTER_ADDRESS, PROVIDER_ADDRESS, XFUND_ADDRESS } = process.env

function sleep (ms) {
  return new Promise(resolve => setTimeout(resolve, ms))
}

module.exports = async function(callback) {

  const data = "BONE.WETH.AD.10"
  const endpoint = web3.utils.asciiToHex(data)

  const xfund = await new web3.eth.Contract(abi, XFUND_ADDRESS)

  const demoConsumer = await DemoConsumer.deployed()
  const accounts = await web3.eth.getAccounts()
  const router = await new web3.eth.Contract(JSON.parse(ROUTER_ABI), ROUTER_ADDRESS)
  const consumerOwner = accounts[0]

  let requestId
  let receipt

  console.log("provider", PROVIDER_ADDRESS)
  console.log("consumerOwner", consumerOwner)
  console.log("demoConsumer", demoConsumer.address)
  console.log("router", ROUTER_ADDRESS)

  console.log("check DemoConsumer xFUND balance")
  const demoConsumerBalance = await xfund.methods.balanceOf(demoConsumer.address).call()
  console.log(`DemoConsumer balance: ${demoConsumerBalance}`)

  if(demoConsumerBalance === "0") {
    console.log("no xFUND - run the comsumer_xfund.js script first")
    callback()
  }

  console.log("check Router's xFUND allowance for DemoConsumer")
  const routerAllowance = await xfund.methods.allowance(demoConsumer.address, ROUTER_ADDRESS).call()

  console.log(`Router allowance: ${routerAllowance}`)

  if(routerAllowance === "0") {
    console.log("no xFUND allowance - run the comsumer_xfund.js script first")
    callback()
  }

  console.log("check fees on Router")
  const fee = await router.methods.getProviderGranularFee(PROVIDER_ADDRESS, demoConsumer.address).call()
  console.log("provider fee currently set at", fee.toString())

  console.log("check fees in demoConsumer")
  const currentFee = await demoConsumer.fee()
  console.log("current fee in demoConsumer contract", currentFee.toString())

  if(fee.toString() !== currentFee.toString()) {
    // set new fee
    console.log("provider fee changed. Update demoConsumer contract")
    receipt = await demoConsumer.setFee(fee, {from: consumerOwner})
    console.log(receipt)
  }

  const priceBefore = await demoConsumer.getPrice()
  console.log("price before", priceBefore.toString())

  try {
    console.log("requesting", data)
    receipt = await demoConsumer.requestData(endpoint, {from: consumerOwner})
    console.log(receipt)
    requestId = receipt.receipt.rawLogs[2].topics[3]
    console.log("requestId", requestId)
  } catch (error) {
    console.log(error)
    callback()
  }

  console.log("waiting for fulfilment. This may take 3 - 4 blocks.")
  for(let i = 0; i <= 1000; i +=1) {
    if(i % 10 === 0 && i > 1) {
      console.log("checking status")
      const status = await router.methods.getRequestStatus(requestId).call()
      const statusInt = parseInt(status, 10)
      const statusTxt = statusInt === 1 ? "requested" : "fulfilled"
      console.log("status:", statusTxt)
      if(statusInt !== 1) {
        console.log("get updated price")
        const priceAfter = await demoConsumer.getPrice()
        console.log("price before", priceBefore.toString())
        console.log("price after ", priceAfter.toString())
        break
      }
    }
    process.stdout.write(".")
    await sleep(500)
  }

  callback()
}
