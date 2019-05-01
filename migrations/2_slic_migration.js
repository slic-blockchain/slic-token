var SlicToken = artifacts.require("SlicToken");

module.exports = function(deployer, network, accounts) {
  // deployment steps
  deployer.deploy(SlicToken, accounts[1], accounts[8], accounts[9], {from: accounts[0]});
};

