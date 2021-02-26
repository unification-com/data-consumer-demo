require("dotenv").config()
const DemoConsumer = artifacts.require("DemoConsumer")

const { ROUTER_ABI, ROUTER_ADDRESS } = process.env

function sleep (ms) {
  return new Promise(resolve => setTimeout(resolve, ms))
}

module.exports = async function(callback) {
  const provider = "0x611661f4B5D82079E924AcE2A6D113fAbd214b14"
  const demoConsumer = await DemoConsumer.deployed()
  const accounts = await web3.eth.getAccounts()
  const router = await new web3.eth.Contract(JSON.parse(ROUTER_ABI), ROUTER_ADDRESS)
  const consumerOwner = accounts[0]

  console.log("provider", provider)
  console.log("consumerOwner", consumerOwner)
  console.log("demoConsumer", demoConsumer.address)

  const priceBefore = await demoConsumer.price()
  console.log("price before", priceBefore.toString())

  const data = "BTC.GBP.PR.AVC.24H"
  const endpoint = web3.utils.asciiToHex(data)

  console.log("requesting", data)
  const r = await demoConsumer.requestData(provider, endpoint, 80, {from: consumerOwner})
  const requestId = r.receipt.rawLogs[0].topics[3]
  console.log("requestId", requestId)

  console.log("waiting for fulfilment. This may take 3 - 4 blocks.")
  for(let i = 0; i <= 200; i +=1) {
    if(i % 30 === 0 && i > 1) {
      console.log("checking status")
      const status = await router.methods.getRequestStatus(requestId).call()
      if(parseInt(status, 10) !== 1) {
        console.log("fulfilled")
        console.log("get price")
        const priceAfter = await demoConsumer.price()
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
