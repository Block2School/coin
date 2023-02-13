const Token = artifacts.require("Token");

contract('Token', async (accounts) => {
  it('initial supply should be 1000000000000000', async () => {
    devToken = await Token.deployed();
    let supply = await devToken.totalSupply();

    assert.equal(supply.toNumber(), 1000000000000000, "Initial supply is not 1000000000000000");
  });
  it('initial supply should not be 1000000000000001', async () => {
    devToken = await Token.deployed();
    let supply = await devToken.totalSupply();

    assert.notEqual(supply.toNumber(), 1000000000000001, "Initial supply is not 1000000000000001");
  });
  it('Name should be Block2School Coin', async () => {
    devToken = await Token.deployed();
    let name = await devToken.name();

    assert.equal(name, "Block2School Coin", "Name is not Block2School Coin");
  });
  it('Symbol should be B2S', async () => {
    devToken = await Token.deployed();
    let symbol = await devToken.symbol();

    assert.equal(symbol, "B2S", "Symbol is not B2S");
  });
  it('Decimals should be 8', async () => {
    devToken = await Token.deployed();
    let decimals = await devToken.decimals();

    assert.equal(decimals, 8, "Decimals is not 8");
  });
  it('mint should not be successful', async () => {
    devToken = await Token.deployed();
    let err;

    try {
      let mint = await devToken.mint(-1);
    } catch (error) {
      err = error;
    }
    assert.equal(err.reason, 'value out-of-bounds', "Mint is successful");
  });
  it('mint should be successful', async () => {
    devToken = await Token.deployed();
    let mint = await devToken.mint(10000000);

    assert.equal(mint.logs[0].type, 'mined', "Mint is not successful");
  });
  it('transfer should not be successful', async () => {
    devToken = await Token.deployed();
    let err;

    try {
      let transfer = await devToken.transfer(accounts[1], -1);
    } catch (error) {
      err = error;
    }
    assert.equal(err.reason, 'value out-of-bounds', "Transfer is successful");
  });
  it('transfer should be successful', async () => {
    devToken = await Token.deployed();
    let transfer = await devToken.transfer(accounts[1], 10000000);

    assert.equal(transfer.logs[0].type, 'mined', "Transfer is not successful");
  });
  it('allowance should be 0', async () => {
    devToken = await Token.deployed();
    let allowance = await devToken.allowance(accounts[0], accounts[1]);

    assert.equal(allowance.toNumber(), 0, "Allowance is not 0");
  });
  it('approve should not be successful', async () => {
    devToken = await Token.deployed();
    let err;

    try {
      let approve = await devToken.approve(accounts[1], -1);
    } catch (error) {
      err = error;
    }
    assert.equal(err.reason, 'value out-of-bounds', "Approve is successful");
  });
  it('approve should be successful', async () => {
    devToken = await Token.deployed();
    let approve = await devToken.approve(accounts[1], 10000000);

    assert.equal(approve.logs[0].type, 'mined', "Approve is not successful");
  });
  it('allowance should be 10000000', async () => {
    devToken = await Token.deployed();
    let allowance = await devToken.allowance(accounts[0], accounts[1]);

    assert.equal(allowance.toNumber(), 10000000, "Allowance is not 10000000");
  });
  it('transferFrom should not be successful', async () => {
    devToken = await Token.deployed();
    let err;

    try {
      let transferFrom = await devToken.transferFrom(accounts[0], accounts[1], -1);
    } catch (error) {
      err = error;
    }
    assert.equal(err.reason, 'value out-of-bounds', "TransferFrom is successful");
  });
});