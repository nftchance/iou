const {
    time,
    loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("IOU", function () {
    async function deployMockBadgeFixture() {
        const [owner, otherAccount] = await ethers.getSigners();

        const MockBadge = await ethers.getContractFactory("MockBadge");

        const mockBadge = await MockBadge.deploy();

        return { mockBadge, owner, otherAccount };
    }

    async function deployFactoryFixture() {
        const [owner, otherAccount, vaultAccount] = await ethers.getSigners();

        const Factory = await ethers.getContractFactory("IOUFactory");

        const { mockBadge } = await loadFixture(deployMockBadgeFixture);

        await mockBadge.mint(owner.address, 0, 1);

        const creationBadge = {
            token: mockBadge.address,
            id: 0,
            amount: 1
        }

        const factory = await Factory.deploy(otherAccount.address, vaultAccount.address, creationBadge);

        return { factory, mockBadge, owner, otherAccount, vaultAccount };
    }

    async function deployIOUFixture() {
        const { factory, owner, otherAccount } = await loadFixture(deployFactoryFixture);

        const iouReceipt = {
            name: "Test",
            symbol: "Test",
            destinationChain: "Flow",
            destinationAddress: "0x1234",
            destinationDecimals: 18
        }

        const tx = await factory.createIOU(iouReceipt);
        const receipt = await tx.wait();

        const event = receipt.events[receipt.events.length - 1];

        const iouAddress = event.args[0];
        const iou = await ethers.getContractAt("IOU", iouAddress);

        return { iou, factory, owner, otherAccount };
    }

    describe("Factory Deployment", function () {
        it("Should set the right owner", async function () {
            const { factory, owner } = await loadFixture(deployFactoryFixture);

            expect(await factory.owner()).to.equal(owner.address);
        });

        it("Should set the right signer", async function () {
            const { factory, otherAccount } = await loadFixture(deployFactoryFixture);

            const tx = await factory.setSigner(otherAccount.address);
            const receipt = await tx.wait();

            const event = receipt.events[receipt.events.length - 1];

            expect(event.event).to.equal("SignerUpdated");

            const signer = await factory.callStatic.signer();

            expect(signer).to.equal(otherAccount.address);
        });

        it("Should set the right vault", async function () {
            const { factory, otherAccount } = await loadFixture(deployFactoryFixture);

            const tx = await factory.setVault(otherAccount.address);
            const receipt = await tx.wait();

            const event = receipt.events[receipt.events.length - 1];

            expect(event.event).to.equal("VaultUpdated");

            const vault = await factory.callStatic.vault();

            expect(vault).to.equal(otherAccount.address);
        });

        it("fail: Should not have permission to set signer", async function () {
            const { factory, otherAccount } = await loadFixture(deployFactoryFixture);

            await expect(factory.connect(otherAccount).setSigner(otherAccount.address)).to.be.revertedWith("Ownable: caller is not the owner");
        });

        it("Should set the right Vault", async function () {
            const { factory, otherAccount } = await loadFixture(deployFactoryFixture);

            const tx = await factory.setVault(otherAccount.address);
            const receipt = await tx.wait();

            const event = receipt.events[receipt.events.length - 1];

            expect(event.event).to.equal("VaultUpdated");

            const vault = await factory.callStatic.vault();

            expect(vault).to.equal(otherAccount.address);
        });

        it("fail: Should not have permission to set Vault", async function () {
            const { factory, otherAccount } = await loadFixture(deployFactoryFixture);

            await expect(factory.connect(otherAccount).setVault(otherAccount.address)).to.be.revertedWith("Ownable: caller is not the owner");
        });

        it("Should set the right Badge", async function () {
            const { factory, mockBadge } = await loadFixture(deployFactoryFixture);

            const badge = {
                token: mockBadge.address,
                id: 0,
                amount: 1
            }

            const tx = await factory.setBadge(badge);
            const receipt = await tx.wait();

            const event = receipt.events[receipt.events.length - 1];

            expect(event.event).to.equal("BadgeUpdated");

            const { token, id, balance } = await factory.callStatic.badge();

            expect(token).to.equal(badge.token);
            expect(id).to.equal(badge.id);
            expect(balance).to.equal(badge.balance);
        });

        it("fail: Should not have permission to set Badge", async function () {
            const { factory, mockBadge, otherAccount } = await loadFixture(deployFactoryFixture);

            const badge = {
                token: mockBadge.address,
                id: 0,
                amount: 2
            }

            await expect(factory.connect(otherAccount).setBadge(badge)).to.be.revertedWith("Ownable: caller is not the owner");
        });
    });

    describe("IOU Usage", function () {
        it("Should create an IOU", async function () {
            const { factory, owner } = await loadFixture(deployFactoryFixture);

            const iouReceipt = {
                name: "Test",
                symbol: "Test",
                destinationChain: "Flow",
                destinationAddress: "0x1234",
                destinationDecimals: 12
            }

            const tx = await factory.createIOU(iouReceipt);
            const receipt = await tx.wait();

            const event = receipt.events[receipt.events.length - 1];

            expect(event.event).to.equal("IOUCreated");

            const iouAddress = event.args[0];
            const iou = await ethers.getContractAt("IOU", iouAddress);
            expect(iou.address).to.equal(iouAddress);

            expect(await iou.destinationChain()).to.equal(iouReceipt.destinationChain);
            expect(await iou.destinationAddress()).to.equal(iouReceipt.destinationAddress);
            expect(await iou.destinationDecimals()).to.equal(iouReceipt.destinationDecimals);

            expect(await iou.factory()).to.equal(factory.address);

            const destinationUpdatedEvent = (await iou.queryFilter(anyValue()))[0]
            expect(destinationUpdatedEvent.event).to.equal("DestinationUpdated");

            const deployer = event.args[1];
            expect(deployer).to.equal(owner.address);

            const iouId = event.args[2];
            expect(iouId).to.equal(0);
        });

        it("fail: Should not have permission to create an IOU", async function () {
            const { factory, otherAccount } = await loadFixture(deployFactoryFixture);

            const iouReceipt = {
                name: "Test",
                symbol: "Test",
                destinationChain: "Flow",
                destinationAddress: "0x1234",
                destinationDecimals: 12
            }

            await expect(factory.connect(otherAccount).createIOU(iouReceipt)).to.be.revertedWith("IOU: Missing Badge that grants access to mint.");
        });

        it("Should issue an IOU", async function () {
            const { iou, owner, otherAccount } = await loadFixture(deployIOUFixture);

            const amount = 100;
            const nonce = 0;

            const minutes = 5;
            const duration = 60 * minutes;
            const expiry = Math.floor(Date.now() / 1000) + duration;

            const message = ethers.utils.solidityKeccak256(
                ["address", "address", "uint256", "uint256", "uint256"],
                [iou.address, otherAccount.address, amount, nonce, expiry]
            );

            const signature = await otherAccount.signMessage(ethers.utils.arrayify(message));

            await iou.issue(otherAccount.address, amount, nonce, expiry, signature);
        });

        it("fail: Should not issue an IOU with an invalid nonce", async function () {
            const { iou, otherAccount } = await loadFixture(deployIOUFixture);

            const amount = 100;
            const nonce = 1;

            const minutes = 5;
            const duration = 60 * minutes;
            const expiry = Math.floor(Date.now() / 1000) + duration;

            const message = ethers.utils.solidityKeccak256(
                ["address", "address", "uint256", "uint256", "uint256"],
                [iou.address, otherAccount.address, amount, nonce, expiry]
            );

            const signature = await otherAccount.signMessage(ethers.utils.arrayify(message));

            await expect(iou.issue(otherAccount.address, amount, nonce, expiry, signature)).to.be.revertedWith("IOU: Invalid nonce.");
        });

        it("fail: Should not issue an IOU with an invalid expiry", async function () {
            const { iou, otherAccount } = await loadFixture(deployIOUFixture);

            const amount = 100;
            const nonce = 0;

            const minutes = 5;
            const duration = 60 * minutes;
            const expiry = Math.floor(Date.now() / 1000) - duration;

            const message = ethers.utils.solidityKeccak256(
                ["address", "address", "uint256", "uint256", "uint256"],
                [iou.address, otherAccount.address, amount, nonce, expiry]
            );

            const signature = await otherAccount.signMessage(ethers.utils.arrayify(message));

            await expect(iou.issue(otherAccount.address, amount, nonce, expiry, signature)).to.be.revertedWith("IOU: Signature expired.");
        });


        it("fail: Should not issue an IOU with an invalid signature", async function () {
            const { iou, owner, otherAccount } = await loadFixture(deployIOUFixture);

            const amount = 100;
            const nonce = 0;

            const minutes = 5;
            const duration = 60 * minutes;
            const expiry = Math.floor(Date.now() / 1000) + duration;

            const message = ethers.utils.solidityKeccak256(
                ["address", "address", "uint256", "uint256", "uint256"],
                [iou.address, otherAccount.address, amount, nonce, expiry]
            );

            const signature = await owner.signMessage(ethers.utils.arrayify(message));

            await expect(iou.issue(otherAccount.address, amount, nonce, expiry, signature)).to.be.revertedWith("IOU: Invalid signature.");
        });

        it("Should redeem an IOU", async function () {
            const { iou, otherAccount } = await loadFixture(deployIOUFixture);

            const amount = 100;
            const nonce = 0;

            const minutes = 5;
            const duration = 60 * minutes;
            const expiry = Math.floor(Date.now() / 1000) + duration;

            const message = ethers.utils.solidityKeccak256(
                ["address", "address", "uint256", "uint256", "uint256"],
                [iou.address, otherAccount.address, amount, nonce, expiry]
            );

            const signature = await otherAccount.signMessage(ethers.utils.arrayify(message));

            await iou.issue(otherAccount.address, amount, nonce, expiry, signature);

            await iou.connect(otherAccount).redeem(amount);
        });

        it("Should burn an IOU", async function () {
            const { iou, otherAccount } = await loadFixture(deployIOUFixture);

            const amount = 100;
            const nonce = 0;

            const minutes = 5;
            const duration = 60 * minutes;
            const expiry = Math.floor(Date.now() / 1000) + duration;

            const message = ethers.utils.solidityKeccak256(
                ["address", "address", "uint256", "uint256", "uint256"],
                [iou.address, otherAccount.address, amount, nonce, expiry]
            );

            const signature = await otherAccount.signMessage(ethers.utils.arrayify(message));

            await iou.issue(otherAccount.address, amount, nonce, expiry, signature);

            await iou.connect(otherAccount).burn(amount);
        });
    });
});
