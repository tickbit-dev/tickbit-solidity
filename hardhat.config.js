require("@nomiclabs/hardhat-waffle");
const fs = require("fs");

const projectId = "ry1msjt2tmDTngdZSGWoZ2rcHXUcbBB3";
const secretKey = fs.readFileSync(".secret").toString();

module.exports = {
	defaultNetwork: "hardhat",
	networks: {
		hardhat: {
			chainId: 1337,
			forking: {
				url: `https://polygon-mumbai.g.alchemy.com/v2/${projectId}`
			}
		},
  		mumbai: {
			url: `https://polygon-mumbai.g.alchemy.com/v2/${projectId}`,
			accounts: [secretKey]
  		},
		mainnet: {
			url: `https://polygon-mainnet.infura.io/v3/${projectId}`,
			accounts: [secretKey]
		}
	},
	solidity: {
		version: "0.8.4",
		settings: {
			optimizer: {
				enabled: true,
				runs: 200
			}
		}
	}
};
