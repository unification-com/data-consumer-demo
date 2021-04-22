require("dotenv").config()
const DemoConsumer = artifacts.require("DemoConsumer")

const { FEE, PROVIDER_ADDRESS, ROUTER_ADDRESS, XFUND_ADDRESS } = process.env

module.exports = function(deployer) {
  deployer.deploy(DemoConsumer, ROUTER_ADDRESS, XFUND_ADDRESS, PROVIDER_ADDRESS, FEE)
}
