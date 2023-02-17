const SolidityContract = artifacts.require("Token");
const Ownable = artifacts.require("Ownable"); 
const Stackable = artifacts.require("Stackable");

module.exports = function(deployer) {
  // Deploy the SolidityContract contract as our only task
  deployer.deploy(SolidityContract);

  // deployer.deploy(Ownable);
  // deployer.deploy(Stackable);
};