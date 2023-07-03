// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBEP20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
}

contract TokenVault {
    address public owner;
    address public bep20TokenAddress;
    // uint256 public BEP20_TOKEN_RATIO = 1470588235294118;
                                    //    1470588235294117500
    uint256 public BEP20_TOKEN_RATIO = 14705882352941175000000;


    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    constructor(address _bep20TokenAddress) {
        owner = msg.sender;
        bep20TokenAddress = _bep20TokenAddress;
    }

    function depositBNB() public payable {
        require(msg.value > 0, "Amount must be greater than 0.");
        uint256 bep20TokenAmount = msg.value * BEP20_TOKEN_RATIO / 10 ** 18;
        require(IBEP20(bep20TokenAddress).balanceOf(address(this)) >= bep20TokenAmount, "Not enough BEP20 balance in the contract to fulfill the deposit.");

        IBEP20(bep20TokenAddress).transfer(msg.sender, bep20TokenAmount);
    }

    function depositBEP20(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0.");
        require(IBEP20(bep20TokenAddress).balanceOf(msg.sender) >= amount, "Insufficient balance.");
        require(IBEP20(bep20TokenAddress).allowance(msg.sender, address(this)) >= amount, "Contract not authorized to spend BEP20 tokens.");

        IBEP20(bep20TokenAddress).transferFrom(msg.sender, address(this), amount);
    }

    function withdrawBNB(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Not enough BNB balance in the contract.");
        payable(owner).transfer(amount);
    }

    function withdrawBEP20(uint256 amount) public onlyOwner {
        require(amount <= IBEP20(bep20TokenAddress).balanceOf(address(this)), "Not enough BEP20 balance in the contract.");
        IBEP20(bep20TokenAddress).transfer(owner, amount);
    }

    function getExchangeRate() public view returns (uint256) {
        return BEP20_TOKEN_RATIO;
    }

    function getContractBalance() public view returns (uint256 bnbBalance, uint256 bep20Balance) {
        return (address(this).balance, IBEP20(bep20TokenAddress).balanceOf(address(this)));
    }

    function changeExchangeRate(uint256 newRatio) public onlyOwner {
        require(newRatio > 0, "Ratio must be greater than 0.");
        BEP20_TOKEN_RATIO = newRatio;
    }

    function changeBEP20Token(address newBEP20TokenAddress) public onlyOwner {
        bep20TokenAddress = newBEP20TokenAddress;
    }
}
