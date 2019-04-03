const BN = require('bn.js');
const time = require('./helpers/timeHelper');

const SlicToken = artifacts.require("./SlicToken");
const SlicDeploymentToken = artifacts.require("./SlicDeploymentToken");
let slic_main;



contract("SlicToken", (accounts) => {
    beforeEach(async () => {
        slic_main = await SlicToken.new({ from: accounts[0] });
    });

    it('creation: should create an initial total supply of 0', async () => {
        // slic_main = await SlicToken.deployed();
        const totalSupply = await slic_main.totalSupply.call();
        assert.strictEqual(totalSupply.toNumber(), 0);
    });

    it('first deployment: should mint 15625000 tokens for the first deployment', async () => {
        // slic_main = await SlicToken.deployed();
        await slic_main.createDeploymentToken(1, {from: accounts[0]});
        const totalSupply = await slic_main.totalSupply();
        const decimals = await slic_main.decimals.call();

        assert.strictEqual(totalSupply.cmp(new BN(15625000).mul(new BN(10).pow(decimals))), 0);
    });

    it('second deployment: should mint 12500000 tokens for the second deployment', async () => {
        // slic_main = await SlicToken.deployed();
        await slic_main.createDeploymentToken(1, {from: accounts[0]});
        await slic_main.createDeploymentToken(2, {from: accounts[0]});
        const totalSupply = await slic_main.totalSupply();
        const decimals = await slic_main.decimals.call();

        assert.strictEqual(totalSupply.cmp(new BN(15625000 + 12500000).mul(new BN(10).pow(decimals))), 0);
    });

    it('second deployment: should distribute 1000 subtokens from the second deployment to acc[1]', async () => {
        // slic_main = await SlicToken.deployed();
        await slic_main.createDeploymentToken(1, {from: accounts[0]});
        await slic_main.createDeploymentToken(2, {from: accounts[0]});

        const subtoken1 = await slic_main.deploymentTokens.call(1);
        const slic_sub1 = await SlicDeploymentToken.at(subtoken1);
        await slic_main.distribute(accounts[1], 1000, 1, {from: accounts[0]});
        let balanceAcc1Sub1 = await slic_sub1.balanceOf.call(accounts[1]);
        assert.strictEqual(balanceAcc1Sub1.cmp(new BN(1000)), 0);

        const subtoken2 = await slic_main.deploymentTokens.call(2);
        const slic_sub2 = await SlicDeploymentToken.at(subtoken2);
        await slic_main.distribute(accounts[1], 1000, 2, {from: accounts[0]});
        const balanceAcc1Sub = await slic_sub2.balanceOf.call(accounts[1]);
        assert.strictEqual(balanceAcc1Sub.cmp(new BN(1000)), 0);

        await slic_sub1.startLockUpCountdown();
        await slic_sub2.startLockUpCountdown();

        const unlockTime2 = await slic_sub2.unlockTime.call();
        const lastblock = await web3.eth.getBlock();
        assert.isTrue(unlockTime2 - (180 * 24 * 60 * 60) > lastblock.timestamp);
        const lastblock2 = await time.advanceTimeAndBlock((183 * 24 * 60 * 60));
        assert.isTrue(unlockTime2 < lastblock2.timestamp);

        await slic_main.redeemUnlockedTokens(2, {from: accounts[1]});
        const balanceAcc1Sub2 = await slic_sub2.balanceOf.call(accounts[1]);
        let balanceAcc1Main = await slic_main.balanceOf.call(accounts[1]);
        assert.strictEqual(balanceAcc1Sub2.cmp(new BN(0)), 0);
        assert.strictEqual(balanceAcc1Main.cmp(new BN(1000)), 0);

        await slic_main.forceRedeemUnlockedTokens(1, accounts[1], {from: accounts[0]});
        balanceAcc1Sub1 = await slic_sub1.balanceOf.call(accounts[1]);
        balanceAcc1Main = await slic_main.balanceOf.call(accounts[1]);
        assert.strictEqual(balanceAcc1Sub1.cmp(new BN(0)), 0);
        assert.strictEqual(balanceAcc1Main.cmp(new BN(2000)), 0);
    });

    it('token holders: should track the current main token holders set', async () => {
        await slic_main.createDeploymentToken(1, {from: accounts[0]});

        await slic_main.distribute(accounts[1], 1000, 1, {from: accounts[0]});
        await slic_main.distribute(accounts[2], 2000, 1, {from: accounts[0]});
        await slic_main.distribute(accounts[3], 3000, 1, {from: accounts[0]});
        await slic_main.distribute(accounts[4], 4000, 1, {from: accounts[0]});
        await slic_main.distribute(accounts[5], 5000, 1, {from: accounts[0]});


        const subtoken1 = await slic_main.deploymentTokens.call(1);
        const slic_sub1 = await SlicDeploymentToken.at(subtoken1);
        await slic_sub1.startLockUpCountdown();
        await time.advanceTimeAndBlock((183 * 24 * 60 * 60));
        await slic_main.redeemUnlockedTokens(1, {from: accounts[1]});
        await slic_main.redeemUnlockedTokens(1, {from: accounts[2]});
        await slic_main.redeemUnlockedTokens(1, {from: accounts[3]});
        await slic_main.redeemUnlockedTokens(1, {from: accounts[4]});
        await slic_main.redeemUnlockedTokens(1, {from: accounts[5]});

        let holdersSet = await slic_main.getHolders.call({from: accounts[1]});
        assert.isTrue(holdersSet.includes(accounts[4]));

        await slic_main.transfer(accounts[6], 4000, {from: accounts[4]});
        await slic_main.transfer(accounts[6], 3000, {from: accounts[3]});

        holdersSet = await slic_main.getHolders.call({from: accounts[2]});
        assert.isFalse(holdersSet.includes(accounts[4]));
        assert.isTrue(holdersSet.includes(accounts[6]));
    });
});

