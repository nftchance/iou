const {
    time,
    loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("IOU", function () {
    async function deployFactoryFixture() {
        const [owner, otherAccount] = await ethers.getSigners();

        const Factory = await ethers.getContractFactory("IOUFactory");
        const factory = await Factory.deploy();

        return { factory, owner, otherAccount };
    }

    async function deployIOUFixture() {
        const [owner, otherAccount] = await ethers.getSigners();

        // Use the factory to deploy a new IOU
        const { factory } = await loadFixture(deployFactoryFixture);
        const tx = await factory.createIOU(owner.address, otherAccount.address);
        const receipt = await tx.wait();
        const iouAddress = receipt.events[0].args[0];
        const iou = await ethers.getContractAt("IOU", iouAddress);

        return { iou, owner, otherAccount };
    }

    async function deployMockBadgeFixture() {
        const [owner, otherAccount] = await ethers.getSigners();

        const MockBadge = await ethers.getContractFactory("MockBadge");

        const mockBadge = await MockBadge.deploy();

        return { mockBadge, owner, otherAccount };
    }

    describe("Factory Deployment", function () {
        it("Should set the right owner", async function () {
            const { factory, owner } = await loadFixture(deployFactoryFixture);

            expect(await factory.owner()).to.equal(owner.address);
        });

        it("Should set the right signer", async function () {
            const { factory, owner, otherAccount } = await loadFixture(deployFactoryFixture);

            factory.setSigner(otherAccount.address);

            const signer = await factory.callStatic.signer();

            expect(signer).to.equal(otherAccount.address);
        });

        it("Should set the right vault", async function () {
            const { factory, owner, otherAccount } = await loadFixture(deployFactoryFixture);

            factory.setVault(otherAccount.address);

            const vault = await factory.callStatic.vault();

            expect(vault).to.equal(otherAccount.address);
        });

        it("Should set the right Badge", async function () {
            const { factory } = await loadFixture(deployFactoryFixture);
            const { mockBadge } = await loadFixture(deployMockBadgeFixture);

            const badge = {
                token: mockBadge.address,
                id: 0,
                amount: 1
            }

            await factory.setBadge(badge);

            const badgeFromFactory = await factory.badge();

            expect(badgeFromFactory.token).to.equal(badge.token);
            expect(badgeFromFactory.id).to.equal(badge.id);
            expect(badgeFromFactory.balance).to.equal(badge.balance);
        });
    });

    // TODO: IOU Creation
});
