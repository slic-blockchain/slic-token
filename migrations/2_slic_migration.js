var SlicToken = artifacts.require("SlicToken");

module.exports = function(deployer, network, accounts) {
  // deployment steps
  deployer.deploy(SlicToken, {from: accounts[0]});
};

