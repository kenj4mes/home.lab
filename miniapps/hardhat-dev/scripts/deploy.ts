import { ethers } from "hardhat";

async function main() {
  console.log("Deploying HomelabToken...");

  const HomelabToken = await ethers.getContractFactory("HomelabToken");
  const token = await HomelabToken.deploy();
  await token.waitForDeployment();

  const address = await token.getAddress();
  console.log(`HomelabToken deployed to: ${address}`);

  // Verify deployment
  const name = await token.name();
  const symbol = await token.symbol();
  const totalSupply = await token.totalSupply();
  const maxSupply = await token.MAX_SUPPLY();

  console.log(`\nToken Details:`);
  console.log(`  Name: ${name}`);
  console.log(`  Symbol: ${symbol}`);
  console.log(`  Total Supply: ${ethers.formatEther(totalSupply)} ${symbol}`);
  console.log(`  Max Supply: ${ethers.formatEther(maxSupply)} ${symbol}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
