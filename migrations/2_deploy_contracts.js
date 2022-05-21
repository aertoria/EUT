var EutMusic = artifacts.require("./EutMusic.sol");

module.exports = function(deployer) {
  deployer.deploy(EutMusic, "EUT", 2330298);
};