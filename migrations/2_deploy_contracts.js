const auctionRepository = artifacts.require("AuctionRepository");
const deedRepository = artifacts.require("DeedRepository");

module.exports = function (deployer) {
  deployer.deploy(auctionRepository);
  deployer.deploy(deedRepository, "HeroToken", "HERO");
};
