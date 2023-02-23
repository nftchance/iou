require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-abi-exporter");

require("dotenv").config();

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
    const accounts = await hre.ethers.getSigners();

    for (const account of accounts) {
        console.log(account.address);
    }
});


task("deploy", "Deploys the protocol")
    .addFlag("verify", "Verify the deployed contracts on Etherscan")
    .setAction(async (taskArgs, hre) => {
        await hre.run('compile');

        const [deployer] = await ethers.getSigners();
        console.log(`✅ Connected to ${deployer.address}`);

        const chainId = await getChainId()

        const IOUFactory = await ethers.getContractFactory("IOUFactory");

        const badgeAddress = "0x0"

        const creationBadge = {
            token: badgeAddress,
            id: 0,
            amount: 1
        }

        iouFactory = await IOUFactory.deploy(deployer.address, signerAddress, creationBadge);
        iouFactory = await iouFactory.deployed();
        console.log("✅ IOUFactory deployed.")

        factoryDeployment = {
            "Chain ID": chainId,
            "Deployer": deployer.address,
            "Organization Implementation Address": iouFactory.address,
            "Remaining ETH Balance": parseInt((await deployer.getBalance()).toString()) / 1000000000000000000,
        }
        console.table(factoryDeployment)

        // Verifying
        if (taskArgs.verify !== false && chainId != '31337') {
            // Give time for etherscan to confirm the contract before verifying.
            await new Promise(r => setTimeout(r, 30000));
            await hre.run("verify:verify", {
                address: iouFactory.address,
                constructorArguments: [
                    deployer.address,
                    signerAddress,
                    creationBadge
                ],
            });

            console.log("✅ IOUFactory Verified.")
        }
    });


module.exports = {
    solidity: {
        compilers: [
            {
                version: "0.8.16",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 1000000
                    }
                }
            }
        ],
    },
    etherscan: {
        apiKey: {
            polygon: process.env.ETHERSCAN_KEY,
        }
    },
    gasReporter: {
        enabled: true,
        currency: 'USD',
        gasPrice: 20,
        coinmarketcap: process.env.COINMARKETCAP_KEY,
        showMethodSig: true,
        showTimeSpent: true,
    },
    networks: {
        polygon: {
            url: `https://polygon-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_KEY}`,
            accounts: [`0x${process.env.PRIVATE_KEY}`],
            gasPrice: 'auto'
        },
    },
    abiExporter: {
        path: './abis/',
        runOnCompile: true,
        clear: true,
        flat: true,
        spacing: 2,
        format: "json"
    }
};
