const BN = require('bn.js');
const time = require('./helpers/timeHelper');
const h = require('./helpers/utils');

const SlicToken = artifacts.require("./SlicToken");
const MultiSigAdmin = artifacts.require("./MultiSigAdmin");
const SlicDeploymentToken = artifacts.require("./SlicDeploymentToken");
let slic_main, multisig_admin;



contract("SlicToken", (accounts) => {
    let icoManagerAddress = accounts[0];

    let adminAddress1 = accounts[1];
    let adminAddress2 = accounts[8];
    let adminAddress3 = accounts[9];

    beforeEach(async () => {
        slic_main = await SlicToken.new(adminAddress1, adminAddress2, adminAddress3, { from: icoManagerAddress });
        await slic_main.initMultisigAdmin({from: icoManagerAddress});
        multisig_admin = await MultiSigAdmin.at(await slic_main.multiSigAdmin());
    });

    it('creation: fails to initialize with duplicate admin addresses', async () => {
        await h.assertRevert(SlicToken.new(adminAddress1, adminAddress1, adminAddress3, { from: icoManagerAddress }));
    });

    it('creation: should create an initial total supply of 0', async () => {
        const totalSupply = await slic_main.totalSupply.call();
        assert.strictEqual(totalSupply.toNumber(), 0);
    });

    it('first deployment: should mint 16429638 tokens for the first deployment', async () => {
        await slic_main.createDeploymentToken(1, {from: icoManagerAddress});
        const totalSupply = await slic_main.totalSupply();
        const decimals = await slic_main.decimals.call();

        assert.strictEqual(totalSupply.cmp(new BN(16429638).mul(new BN(10).pow(decimals))), 0);
    });

    it('deployment: should mint the correct amount of tokens for all and each deployment', async () => {
        // slic_main = await SlicToken.deployed();
        await slic_main.createDeploymentToken(1, {from: icoManagerAddress});
        await slic_main.createDeploymentToken(2, {from: icoManagerAddress});
        let totalSupply = await slic_main.totalSupply();
        let decimals = await slic_main.decimals.call();

        assert.strictEqual(totalSupply.cmp(new BN(16429638 + 12500000).mul(new BN(10).pow(decimals))), 0);

        for(var i = 3; i <= 60; i++) {
            await slic_main.createDeploymentToken(i, {from: icoManagerAddress});
            if(i == 3 || i == 10) {
                const subtokenR2a = await slic_main.deploymentTokens.call(i);
                const slic_subR2a = await SlicDeploymentToken.at(subtokenR2a);
                const totalSupply = await slic_subR2a.totalSupply();
                const decimals = await slic_subR2a.decimals.call();

                assert.strictEqual(totalSupply.cmp(new BN(12500000).mul(new BN(10).pow(decimals))), 0);
            }
            if(i == 11 || i == 20) {
                const subtokenR2b = await slic_main.deploymentTokens.call(i);
                const slic_subR2b = await SlicDeploymentToken.at(subtokenR2b);
                const totalSupply = await slic_subR2b.totalSupply();
                const decimals = await slic_subR2b.decimals.call();

                assert.strictEqual(totalSupply.cmp(new BN(9765625).mul(new BN(10).pow(decimals))), 0);
            }
            if(i == 21 || i == 40) {
                const subtokenR3 = await slic_main.deploymentTokens.call(i);
                const slic_subR3 = await SlicDeploymentToken.at(subtokenR3);
                const totalSupply = await slic_subR3.totalSupply();
                const decimals = await slic_subR3.decimals.call();

                assert.strictEqual(totalSupply.cmp(new BN(7812500).mul(new BN(10).pow(decimals))), 0);
            }
            if(i == 41 || i == 60) {
                const subtokenR4 = await slic_main.deploymentTokens.call(i);
                const slic_subR4 = await SlicDeploymentToken.at(subtokenR4);
                const totalSupply = await slic_subR4.totalSupply();
                const decimals = await slic_subR4.decimals.call();

                assert.strictEqual(totalSupply.cmp(new BN(6250000).mul(new BN(10).pow(decimals))), 0);
            }
        }

        totalSupply = await slic_main.totalSupply();
        assert.strictEqual(totalSupply.cmp(new BN(507835888).mul(new BN(10).pow(decimals))), 0);
    });

    it('second deployment: should distribute 1000 subtokens from the second deployment to acc[2]', async () => {
        // slic_main = await SlicToken.deployed();
        await slic_main.createDeploymentToken(1, {from: icoManagerAddress});
        await slic_main.createDeploymentToken(2, {from: icoManagerAddress});

        const subtoken1 = await slic_main.deploymentTokens.call(1);
        const slic_sub1 = await SlicDeploymentToken.at(subtoken1);
        await slic_main.distribute(accounts[2], 1000, 1, {from: icoManagerAddress});
        let balanceAcc1Sub1 = await slic_sub1.balanceOf.call(accounts[2]);
        assert.strictEqual(balanceAcc1Sub1.cmp(new BN(1000)), 0);

        const subtoken2 = await slic_main.deploymentTokens.call(2);
        const slic_sub2 = await SlicDeploymentToken.at(subtoken2);
        await slic_main.distribute(accounts[2], 1000, 2, {from: icoManagerAddress});
        const balanceAcc1Sub = await slic_sub2.balanceOf.call(accounts[2]);
        assert.strictEqual(balanceAcc1Sub.cmp(new BN(1000)), 0);

        await slic_main.startLockUpCountdown(1, {from: icoManagerAddress});
        await slic_main.startLockUpCountdown(2, {from: icoManagerAddress});

        const unlockTime2 = await slic_sub2.unlockTime.call();
        const lastblock = await web3.eth.getBlock();
        assert.isTrue(unlockTime2 - (180 * 24 * 60 * 60) > lastblock.timestamp);
        const lastblock2 = await time.advanceTimeAndBlock((183 * 24 * 60 * 60));
        assert.isTrue(unlockTime2 < lastblock2.timestamp);

        await slic_main.redeemUnlockedTokens(2, {from: accounts[2]});
        const balanceAcc1Sub2 = await slic_sub2.balanceOf.call(accounts[2]);
        let balanceAcc1Main = await slic_main.balanceOf.call(accounts[2]);
        assert.strictEqual(balanceAcc1Sub2.cmp(new BN(0)), 0);
        assert.strictEqual(balanceAcc1Main.cmp(new BN(1000)), 0);

        await slic_main.forceRedeemUnlockedTokens(1, accounts[2], {from: icoManagerAddress});
        balanceAcc1Sub1 = await slic_sub1.balanceOf.call(accounts[2]);
        balanceAcc1Main = await slic_main.balanceOf.call(accounts[2]);
        assert.strictEqual(balanceAcc1Sub1.cmp(new BN(0)), 0);
        assert.strictEqual(balanceAcc1Main.cmp(new BN(2000)), 0);
    });

    it('token holders: should track the current main token holders set', async () => {
        await slic_main.createDeploymentToken(1, {from: icoManagerAddress});

        await slic_main.distribute(accounts[2], 2000, 1, {from: icoManagerAddress});
        await slic_main.distribute(accounts[3], 3000, 1, {from: icoManagerAddress});
        await slic_main.distribute(accounts[4], 4000, 1, {from: icoManagerAddress});
        await slic_main.distribute(accounts[5], 5000, 1, {from: icoManagerAddress});
        await slic_main.distribute(accounts[6], 6000, 1, {from: icoManagerAddress});


        const subtoken1 = await slic_main.deploymentTokens.call(1);
        const slic_sub1 = await SlicDeploymentToken.at(subtoken1);
        await slic_main.startLockUpCountdown(1, {from: icoManagerAddress});
        await time.advanceTimeAndBlock((183 * 24 * 60 * 60));
        await slic_main.redeemUnlockedTokens(1, {from: accounts[2]});
        await slic_main.redeemUnlockedTokens(1, {from: accounts[3]});
        await slic_main.redeemUnlockedTokens(1, {from: accounts[4]});
        await slic_main.redeemUnlockedTokens(1, {from: accounts[5]});
        await slic_main.redeemUnlockedTokens(1, {from: accounts[6]});

        let holdersSet = await slic_main.getHolders.call({from: icoManagerAddress});
        assert.isTrue(holdersSet.includes(accounts[4]));

        await slic_main.transfer(accounts[7], 4000, {from: accounts[4]});
        await slic_main.transfer(accounts[7], 3000, {from: accounts[3]});

        holdersSet = await slic_main.getHolders.call({from: accounts[2]});
        assert.isFalse(holdersSet.includes(accounts[4]));
        assert.isTrue(holdersSet.includes(accounts[7]));

        // zero tokens transfer does not add the receiver to the holders set
        await slic_main.distribute(accounts[8], 0, 1, {from: icoManagerAddress});
        await slic_main.redeemUnlockedTokens(1, {from: accounts[8]});
        holdersSet = await slic_main.getHolders.call({from: icoManagerAddress});
        assert.isFalse(holdersSet.includes(accounts[8]));

        // last holder does not remain a holder after transferring out all of their tokens
        await slic_main.transfer(accounts[2], 7000, {from: accounts[7]});
        holdersSet = await slic_main.getHolders.call({from: icoManagerAddress});
        assert.isFalse(holdersSet.includes(accounts[7]));
    });

    it('admin access: the admin can freeze a token holder', async () => {
        await slic_main.createDeploymentToken(1, {from: icoManagerAddress});
        await slic_main.distribute(accounts[2], 1000, 1, {from: icoManagerAddress});
        const subtoken1 = await slic_main.deploymentTokens.call(1);
        const slic_sub1 = await SlicDeploymentToken.at(subtoken1);
        await slic_main.startLockUpCountdown(1, {from: icoManagerAddress});
        await time.advanceTimeAndBlock((183 * 24 * 60 * 60));
        await slic_main.redeemUnlockedTokens(1, {from: accounts[2]});

        let isFrozen = await slic_main.frozen(accounts[2]);
        assert.isFalse(isFrozen);

        let isSuccessfulTransfer = await slic_main.transfer.call(accounts[3], 1, {from: accounts[2]});
        assert.isTrue(isSuccessfulTransfer);

        const freezeTx = await multisig_admin.toggleFreeze(accounts[2], true, 0, {from: adminAddress1});
        const proposalBlockNum = freezeTx.receipt.blockNumber;

        await multisig_admin.toggleFreeze(accounts[2], true, proposalBlockNum, {from: adminAddress2});

        isFrozen = await slic_main.frozen(accounts[2]);
        assert.isTrue(isFrozen);

        isSuccessfulTransfer = await slic_main.transfer.call(accounts[3], 1, {from: accounts[2]});
        assert.isFalse(isSuccessfulTransfer);
    });

    it('admin access: no other address can freeze a token holder', async () => {
        await slic_main.createDeploymentToken(1, {from: icoManagerAddress});
        await slic_main.distribute(accounts[2], 1000, 1, {from: icoManagerAddress});
        const subtoken1 = await slic_main.deploymentTokens.call(1);
        const slic_sub1 = await SlicDeploymentToken.at(subtoken1);
        await slic_main.startLockUpCountdown(1, {from: icoManagerAddress});
        await time.advanceTimeAndBlock((183 * 24 * 60 * 60));
        await slic_main.redeemUnlockedTokens(1, {from: accounts[2]});

        let isFrozen = await slic_main.frozen(accounts[2]);
        assert.isFalse(isFrozen);

        await h.assertRevert(multisig_admin.toggleFreeze(accounts[2], true, 0, {from: accounts[7]}));
    });

    it('admin access: admin can recover mistakenly sent tokens to the smart contract address', async () => {
        const another_token = await SlicToken.new(accounts[2], accounts[3], accounts[4], { from: accounts[5] });
        await another_token.initMultisigAdmin({from: accounts[5]});

        await another_token.createDeploymentToken(1, {from: accounts[5]});
        await another_token.distribute(accounts[2], 1000, 1, {from: accounts[5]});
        const subtoken1 = await another_token.deploymentTokens.call(1);
        const slic_sub1 = await SlicDeploymentToken.at(subtoken1);
        await another_token.startLockUpCountdown(1, {from: accounts[5]});
        await time.advanceTimeAndBlock((183 * 24 * 60 * 60));
        await another_token.redeemUnlockedTokens(1, {from: accounts[2]});

        await another_token.transfer(slic_main.address, 345, {from: accounts[2]});

        let balanceMain = await another_token.balanceOf.call(slic_main.address);
        let balanceAdmin3 = await another_token.balanceOf.call(accounts[4]);
        assert.strictEqual(balanceMain.cmp(new BN(345)), 0);
        assert.strictEqual(balanceAdmin3.cmp(new BN(0)), 0);

        const recoverTx = await multisig_admin.recoverERC20Tokens(another_token.address, 0, {from: adminAddress2});
        const proposalBlockNum = recoverTx.receipt.blockNumber;

        balanceMain = await another_token.balanceOf.call(slic_main.address);
        assert.strictEqual(balanceMain.cmp(new BN(345)), 0);

        await multisig_admin.recoverERC20Tokens(another_token.address, proposalBlockNum, {from: adminAddress3});

        balanceMain = await another_token.balanceOf.call(slic_main.address);
        balanceAdmin3 = await another_token.balanceOf.call(adminAddress3);
        assert.strictEqual(balanceMain.cmp(new BN(0)), 0);
        assert.strictEqual(balanceAdmin3.cmp(new BN(345)), 0);
    });

    it('admin access: admins can add another admin and remove themself', async () => {
        let newAdmin = accounts[4];

        let isNewAdminAdmin = await slic_main.isAdmin(newAdmin);
        assert.isFalse(isNewAdminAdmin);

        let addAdminTx = await multisig_admin.addAdmin(newAdmin, 0, {from: adminAddress1});
        let proposalBlockNum = addAdminTx.receipt.blockNumber;

        isNewAdminAdmin = await slic_main.isAdmin(newAdmin);
        assert.isFalse(isNewAdminAdmin);

        await multisig_admin.addAdmin(newAdmin, proposalBlockNum, {from: adminAddress3});

        isNewAdminAdmin = await slic_main.isAdmin(newAdmin);
        assert.isTrue(isNewAdminAdmin);

        let renounceAdminTx = await multisig_admin.renounceAdmin(0, {from: adminAddress2});
        proposalBlockNum = renounceAdminTx.receipt.blockNumber;

        let isOldAdminAdmin = await slic_main.isAdmin(multisig_admin.address);
        assert.isTrue(isOldAdminAdmin);

        await multisig_admin.renounceAdmin(proposalBlockNum, {from: adminAddress3});
        isOldAdminAdmin = await slic_main.isAdmin(multisig_admin.address);
        assert.isFalse(isOldAdminAdmin);
    });
});

