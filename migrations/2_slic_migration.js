var SlicToken = artifacts.require("SlicToken");

module.exports = function(deployer, network, accounts) {
  // deployment steps
  deployer.deploy(SlicToken, accounts[1], {from: accounts[0]});
};

