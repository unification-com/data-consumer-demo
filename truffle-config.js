require("dotenv").config()
const HDWalletProvider = require('@truffle/hdwallet-provider')
const fs = require('fs')

let customNetworks = {}

if (fs.existsSync("./custom_networks.js")) {
  customNetworks = require("./custom_networks").customNetworks
}

const {
  ETH_PKEY,
  INFURA_PROJECT_ID,
  ETHERSCAN_API,
} = process.env

module.exports = {
  networks: {
    // ganache-cli
    development: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 8545,            // Standard Ethereum port (default: none)
      network_id: "*",       // Any network (default: none)
    },
    // truffle develop console
    develop: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
    },
    goerli: {
      provider: () =>
        new HDWalletProvider({
          privateKeys: [ETH_PKEY],
          providerOrUrl: `https://goerli.infura.io/v3/${INFURA_PROJECT_ID}`,
        }),
      network_id: "5",
      gasPrice: 50000000000,
      skipDryRun: true,
    },
    sepolia: {
      provider: () =>
          new HDWalletProvider({
            privateKeys: [ETH_PKEY],
            providerOrUrl: `https://sepolia.infura.io/v3/${INFURA_PROJECT_ID}`,
          }),
      network_id: "11155111",
      gas: 10000000,
      gasPrice: 5000000000,
      skipDryRun: true,
    },
    mainnet: {
      provider: () =>
        new HDWalletProvider({
          privateKeys: [ETH_PKEY],
          providerOrUrl: `https://mainnet.infura.io/v3/${INFURA_PROJECT_ID}`
        }),
      network_id: "1",
      gasPrice: 120000000000 // 120e9 = 120 gwei
    },
    polygon: {
      provider: () =>
        new HDWalletProvider({
          privateKeys: [ETH_PKEY],
          providerOrUrl: `https://polygon-mainnet.infura.io/v3/${INFURA_PROJECT_ID}`,
        }),
      network_id: "137",
      gasPrice: 40000000000, // 40 gwei
      skipDryRun: true,
    },
    ...customNetworks,
  },


  plugins: [
    'truffle-plugin-verify'
  ],

  api_keys: {
    etherscan: ETHERSCAN_API
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.3",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }
  }
};
