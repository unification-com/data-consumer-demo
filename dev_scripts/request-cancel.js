const DemoConsumer = artifacts.require("DemoConsumer");

function sleep (ms) {
  return new Promise(resolve => setTimeout(resolve, ms))
}

module.exports = async function(callback) {
  const provider = "0x611661f4B5D82079E924AcE2A6D113fAbd214b14"
  const demoConsumer = await DemoConsumer.deployed()
  const accounts = await web3.eth.getAccounts()
  const consumerOwner = accounts[0]

  console.log("provider", provider)
  console.log("consumerOwner", consumerOwner)
  console.log("demoConsumer", demoConsumer.address)

  console.log("set request timeout to 1 second to allow quick cancel")
  await demoConsumer.setRequestVar(3, 1, {from: consumerOwner})

  const priceBefore = await demoConsumer.price()
  console.log("price before", priceBefore.toString())

  const data = "BTC.GBP.PR.AVC.24H"
  const endpoint = web3.utils.asciiToHex(data)

  console.log("requesting", data)

  const r = await demoConsumer.requestData(provider, endpoint, 80, {from: consumerOwner})

  const requestId = r.receipt.rawLogs[0].topics[3]

  console.log("requestId", requestId)

  console.log("wait a block")
  for( let i = 0; i < 32; i += 1) {
    process.stdout.write(".")
    await sleep(500)
  }
  console.log("cancel request")

  await demoConsumer.cancelRequest(requestId, {from: consumerOwner})

  const priceAfter = await demoConsumer.price()
  console.log("price before", priceBefore.toString())
  console.log("price after ", priceAfter.toString())

  callback()
}
