require("dotenv").config()
const DemoConsumerCustom = artifacts.require("DemoConsumerCustom")

const { FEE, PROVIDER_ADDRESS, ROUTER_ADDRESS, XFUND_ADDRESS } = process.env

module.exports = function(deployer) {
  deployer.deploy(DemoConsumerCustom, ROUTER_ADDRESS, XFUND_ADDRESS, PROVIDER_ADDRESS, FEE)
}
