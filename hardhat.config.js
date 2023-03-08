require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-abi-exporter");
require('hardhat-deploy');

require("dotenv").config();

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
    const accounts = await hre.ethers.getSigners();

    for (const account of accounts) {
        console.log(account.address);
    }
});

task("mint", "Mints a badge to an address")
    .addParam("badgeAddress", "The address of the badge to mint")
    .addParam("address", "The address to mint to")
    .addParam("id", "The id of the badge to mint")
    .addParam("amount", "The amount of the badge to mint")
    .setAction(async (taskArgs, hre) => {
        const MockToken = await ethers.getContractFactory("MockBadge");

        const mockToken = MockToken.attach(taskArgs.badgeAddress);

        await mockToken.mint(taskArgs.address, taskArgs.id, taskArgs.amount);

        console.log(`✅ Minted ${taskArgs.amount} of badge ${taskArgs.id} to ${taskArgs.address}`)
    });

task("deploy", "Deploys the protocol")
    .addFlag("verify", "Verify the deployed contracts on Etherscan")
    .setAction(async (taskArgs, hre) => {
        await hre.run('compile');

        const [deployer] = await ethers.getSigners();
        console.log(`✅ Connected to ${deployer.address}`);

        const chainId = await getChainId()

        const MockToken = await ethers.getContractFactory("MockBadge");
        const mockToken = await MockToken.deploy();
        mockToken = await mockToken.deployed();

        console.log("✅ MockBadge deployed.")

        await mockToken.mint(deployer.address, 0, 20);
        await mockToken.mint("0x3e2E6134F72ba1Fbb48fD5a840B11de9698E7B6D", 0, 20);

        console.log("✅ MockBadge tokens minted.")

        mockDeployment = {
            "Chain ID": chainId,
            "Deployer": deployer.address,
            "Organization Implementation Address": mockToken.address,
            "Remaining ETH Balance": parseInt((await deployer.getBalance()).toString()) / 1000000000000000000,
        }

        console.table(mockDeployment)

        const IOU = await ethers.getContractFactory("IOU");
        const iou = await IOU.deploy();
        iou = await iou.deployed();

        console.log("✅ Implementation singleton deployed.")

        singletonDeployment = {
            "Chain ID": chainId,
            "Deployer": deployer.address,
            "Organization Implementation Address": iou.address,
            "Remaining ETH Balance": parseInt((await deployer.getBalance()).toString()) / 1000000000000000000,
        }

        console.table(singletonDeployment)

        const singletonAddress = iou.address;
        const signerAddress = "0x0"

        const creationBadge = {
            token: mockToken.address,
            id: 0,
            amount: 1
        }

        iouFactory = await IOUFactory.deploy(singletonAddress, signerAddress, creationBadge);
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
                    singletonAddress,
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
