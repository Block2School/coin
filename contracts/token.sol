// SPDX-License-Identifier: MIT
// contracts/token.sol

pragma solidity >=0.8.0 <0.9.0;

import './ownable.sol';
import './stackable.sol';

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @notice Token is IBEP20 and Ownable
 */

contract Token is IBEP20, Ownable, Stackable {

    string public name_; // The name of the token
    string public symbol_; // The symbol of the token (e.g. SNT)
    uint8 public decimals_; // The number of decimals of the token
    uint256 public totalSupply_; // The total amount of tokens in existence
    address payable public owner_; // The owner of the token

    /* this creates a mapping with all balances */
    mapping (address => uint256) public balanceOf_;

    /* this creates a mapping of accounts with allowances */
    mapping (address => mapping (address => uint256)) public allowance_;

    constructor() {
        name_ = "Block2School Coin";
        symbol_ = "B2S";
        decimals_ = 8;
        uint256 _initialSupply = 10000000 * (10 ** decimals_);

        /* Sets the owner of the token to whoever deployed it */
        owner_ = payable(msg.sender);

        balanceOf_[owner_] = _initialSupply; // transfer the initial supply to the owner
        totalSupply_ = _initialSupply; // set the total supply of tokens

        /* Whenever tokens are created, burnt or transferred, the Transfert event is emitted */
        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    function totalSupply() external view override returns (uint256) {
        return totalSupply_;
    }

    function decimals() external view override returns (uint8) {
        return decimals_;
    }

    function symbol() external view override returns (string memory) {
        return symbol_;
    }

    function name() external view override returns (string memory) {
        return name_;
    }

    function getOwner() external view override returns (address) {
        return owner_;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return balanceOf_[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        uint256 senderBalance = balanceOf_[msg.sender];
        uint256 recipientBalance = balanceOf_[recipient];

        /* Process some checks before the transfer */
        require(recipient != address(0), "Recipient address invalid");
        require(amount >= 0, "Amount must be greater or equal to 0");
        require(senderBalance >= amount, "Sender does not have enough balance");

        /* Transfer the tokens */
        balanceOf_[msg.sender] = senderBalance - amount;
        balanceOf_[recipient] = recipientBalance + amount;

        /* Emit the transfer event */
        emit Transfer(msg.sender, recipient, amount);

        return true;
    }

    function allowance(address _owner, address spender) external view override returns (uint256) {
        return allowance_[_owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        /* Process some checks before the approval */
        require(amount >= 0, "Amount must be greater or equal to 0");
        require(msg.sender != address(0), "address invalid");

        /* Set the allowance */
        allowance_[msg.sender][spender] = amount;

        /* Emit the approval event */
        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        /* Process some checks before the transfer */
        require(recipient != address(0), "Recipient address invalid");
        require(amount >= 0, "Amount must be greater or equal to 0");
        require(balanceOf_[sender] >= amount, "Sender does not have enough balance");
        require(allowance_[sender][msg.sender] >= amount, "Sender does not have enough allowance");

        /* Transfer the tokens */
        balanceOf_[sender] = balanceOf_[sender] - amount;
        balanceOf_[recipient] = balanceOf_[recipient] + amount;
        allowance_[sender][msg.sender] = allowance_[sender][msg.sender] - amount;

        /* Emit the transfer event */
        emit Transfer(sender, recipient, amount);

        return true;
    }

    function mint(uint256 amount) public onlyOwner returns (bool) {
        /* Process some checks before the mint */
        require(amount >= 0, "Amount must be greater or equal to 0");
        require(msg.sender == owner_, "Only the owner can mint tokens");

        /* Mint the tokens */
        balanceOf_[msg.sender] = balanceOf_[msg.sender] + amount;
        totalSupply_ = totalSupply_ + amount;

        /* Emit the mint event */
        emit Transfer(address(0), msg.sender, amount);

        return true;
    }

    function burn(uint256 amount) public onlyOwner returns (bool) {
        /* Process some checks before the burn */
        require(msg.sender != address(0), "Invalid burn recipient");
        require(amount >= 0, "Amount must be greater or equal to 0");
        require(balanceOf_[msg.sender] > amount, "Burn amount exceeds balance");

        /* Burn the tokens */
        balanceOf_[msg.sender] = balanceOf_[msg.sender] - amount;
        totalSupply_ = totalSupply_ - amount;

        /* Emit the burn event */
        emit Transfer(msg.sender, address(0), amount);

        return true;
    }

    /**
    * Add functionality like burn to the _stake function
    *
    */
    function stake(uint256 _amount) public {
        // make sure the user has enough tokens to stake
        require(balanceOf_[msg.sender] > _amount, "Not enough tokens to stake");

        _stake(_amount);
        // burn the tokens
        burn(_amount);
    }

    /**
    * @notice withdrawStake is used to withdraw the staked tokens from the account holder
    */
    function withdrawStake(uint256 _amount) public {
        // make sure the user has enough tokens to withdraw
        // mint the tokens
        mint(_amount);
    }
}