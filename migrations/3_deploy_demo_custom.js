require("dotenv").config()
const DemoConsumerCustom = artifacts.require("DemoConsumerCustom")

const { CONSUMER_LIB_ADDRESS, ROUTER_ADDRESS } = process.env

module.exports = function(deployer) {
  DemoConsumerCustom.link("ConsumerLib", CONSUMER_LIB_ADDRESS)
  deployer.deploy(DemoConsumerCustom, ROUTER_ADDRESS)
}
