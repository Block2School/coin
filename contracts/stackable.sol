// SPDX-License-Identifier: MIT
// contracts/token.sol

pragma solidity >=0.8.0 <0.9.0;

/**
* @notice Stakeable is a contract who is ment to be inherited by other contract that wants Staking capabilities
*/
contract Stackable {

    /**
    * @notice Constructor,since this contract is not ment to be used without inheritance
    * push once to stakeholders for it to work proplerly
    */
    constructor() {
        // this push is needed so we avoid index 0 causing bug of index -1
        stakeholders.push();

    }
    /**
    * @notice
    * A stake struct is used to represent the way we store stakes, 
    * A Stake will contain the users address, the amount staked and a timestamp, 
    * Since which is when the stake was made
    */
    struct Stake{
        address user;
        uint256 amount;
        uint256 since;
    }
    /**
    * @notice Stakeholder is a staker that has active stakes
    */
    struct Stakeholder{
        address user;
        Stake[] address_stakes;
    }

    /**
    * @notice 
    *   This is a array where we store all Stakes that are performed on the Contract
    *   The stakes for each address are stored at a certain index, the index can be found using the stakes mapping
    */
    Stakeholder[] internal stakeholders;
    /**
    * @notice 
    * stakes is used to keep track of the INDEX for the stakers in the stakes array
    */
    mapping(address => uint256) internal stakes;
    /**
    * @notice Staked event is triggered whenever a user stakes tokens, address is indexed to make it filterable
    */
    event Staked(address indexed user, uint256 amount, uint256 index, uint256 timestamp);

    /**
    * @notice _addStakeholder takes care of adding a new stakeholder to the stakeholders array
    */
    function _addStakeholder(address stacker) internal returns (uint256) {
        // push an empty Stakeholder struct to the stakeholders array
        stakeholders.push();
        // calculate the index of the last item in the array by subtracting 1 from the length
        uint256 userIndex = stakeholders.length - 1;
        // set the address to the new index
        stakeholders[userIndex].user = stacker;
        // add index to the stackeholders
        stakes[stacker] = userIndex;

        return userIndex;
    }

    /**
    * @notice
    * _Stake is used to make a stake for an sender. It will remove the amount staked from the stakers account and place those tokens inside a stake container
    * StakeID 
    */
    function _stake(uint256 _amount) internal {
        // check if the amount is greater than 0
        require(_amount > 0, "Stakeable: Amount must be greater than 0");

        uint256 userIndex = stakes[msg.sender];
        uint256 timestamp = block.timestamp;

        if (userIndex == 0) {
            userIndex = _addStakeholder(msg.sender);
        }

        stakeholders[userIndex].address_stakes.push(Stake(msg.sender, _amount, timestamp));

        emit Staked(msg.sender, _amount, userIndex, timestamp);
    }
}