require("dotenv").config()
const DemoConsumer = artifacts.require("DemoConsumer")

const { CONSUMER_LIB_ADDRESS, ROUTER_ADDRESS } = process.env

module.exports = function(deployer) {
  DemoConsumer.link("ConsumerLib", CONSUMER_LIB_ADDRESS)
  deployer.deploy(DemoConsumer, ROUTER_ADDRESS)
}
