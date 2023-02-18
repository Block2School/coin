const SolidityContract = artifacts.require("Token");

module.exports = async function(deployer) {
  // Deploy the SolidityContract contract as our only task
  await deployer.deploy(SolidityContract);
  const tokenContract = await SolidityContract.deployed();
};