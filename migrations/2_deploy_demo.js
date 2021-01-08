require("dotenv").config()
const DemoConsumer = artifacts.require("DemoConsumer")
const DemoConsumerCustom = artifacts.require("DemoConsumerCustom")

const {
  CONSUMER_LIB_ADDRESS,
  ROUTER_ADDRESS,
} = process.env

module.exports = function(deployer) {
  DemoConsumer.link("ConsumerLib", CONSUMER_LIB_ADDRESS)
  DemoConsumerCustom.link("DemoConsumerCustom", CONSUMER_LIB_ADDRESS)
  deployer.deploy(DemoConsumer, ROUTER_ADDRESS)
  deployer.deploy(DemoConsumerCustom, ROUTER_ADDRESS)
}
