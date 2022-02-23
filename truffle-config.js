const HDWalletProvider = require("@truffle/hdwallet-provider");
require("dotenv").config();
const MNEMONIC = process.env.PRIVATE_KEY;

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*",
    },
    ropsten: {
      provider: function () {
        return new HDWalletProvider(
          MNEMONIC,
          "https://ropsten.infura.io/v3/f2cd5c922b284ca5ba481394e4dafee4"
        );
      },
      network_id: 3,
      gas: 4000000, //make sure this gas allocation isn't over 4M, which is the max
    },
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.11", // Fetch exact version from solc-bin (default: truffle's version)
    },
  },
};
