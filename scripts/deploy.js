const hre = require("hardhat");

async function main() {
	const TickbitContract = await hre.ethers.getContractFactory("Tickbit");
	const tickbitContract = await TickbitContract.deploy();

	await tickbitContract.deployed();

	console.log("TickbitContract deployed to:", tickbitContract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
