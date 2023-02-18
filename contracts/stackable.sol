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
        // This claimable field is new and used to tell how big of a reward is currently available
        uint256 claimable;
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
    * StakingSummary is a struct that is used to contain all stakes performed by a certain account
    */ 
    struct StakingSummary{
        uint256 total_amount;
        Stake[] stakes;
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

        stakeholders[userIndex].address_stakes.push(Stake(msg.sender, _amount, timestamp,0));

        emit Staked(msg.sender, _amount, userIndex, timestamp);
    }

    /**
    * @notice
    * rewardPerHour is 1000 because it is used to represent 0.001, since we only use integer numbers
    * This will give users 0.1% reward for each staked token / H
    */
    uint256 internal rewardPerHour = 1000;

    /**
    * @notice
    * calculateStakeReward is used to calculate how much a user should be rewarded for their stakes
    * and the duration the stake has been active
    */
    function calculateStakeReward(Stake memory _current_stake) internal view returns (uint256){
        // First calculate how long the stake has been active
        // Use current seconds since epoch - the seconds since epoch the stake was made
        // The output will be duration in SECONDS ,
        // We will reward the user 0.1% per Hour So thats 0.1% per 3600 seconds
        // the alghoritm is  seconds = block.timestamp - stake seconds (block.timestap - _stake.since)
        // hours = Seconds / 3600 (seconds /3600) 3600 is an variable in Solidity names hours
        // we then multiply each token by the hours staked , then divide by the rewardPerHour rate 
        return (((block.timestamp - _current_stake.since) / 1 hours) * _current_stake.amount) / rewardPerHour;
    }

    /**
    * @notice
    * withdrawStake takes in an amount and a index of the stake and will remove tokens from that stake
    * Notice index of the stake is the users stake counter, starting at 0 for the first stake
    * Will return the amount to MINT onto the acount
    * Will also calculateStakeReward and reset timer
    */
    function _withdrawStake(uint256 amount, uint256 index) internal returns (uint256) {
        // Grab user_index which is the index to use to grab the Stake[]
        uint256 user_index = stakes[msg.sender];
        Stake memory current_stake = stakeholders[user_index].address_stakes[index];
        require(current_stake.amount >= amount, "Staking: Cannot withdraw more than you have staked");

        // Calculate available Reward first before we start modifying data
        uint256 reward = calculateStakeReward(current_stake);
        // Remove by subtracting the money unstaked 
        current_stake.amount = current_stake.amount - amount;
        // If stake is empty, 0, then remove it from the array of stakes
        if (current_stake.amount == 0) {
            delete stakeholders[user_index].address_stakes[index];
        } else {
            // If not empty then replace the value of it
            stakeholders[user_index].address_stakes[index].amount = current_stake.amount;
            // Reset timer of stake
            stakeholders[user_index].address_stakes[index].since = block.timestamp;
        }

        return amount+reward;
    }

    /**
    * @notice
    * hasStake is used to check if a account has stakes and the total amount along with all the seperate stakes
    */
    function hasStake(address _staker) public view returns (StakingSummary memory) {
        // totalStakeAmount is used to count total staked amount of the address
        uint256 totalStakeAmount; 
        // Keep a summary in memory since we need to calculate this
        StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[_staker]].address_stakes);
        // Itterate all stakes and grab amount of stakes
        for (uint256 s = 0; s < summary.stakes.length; s += 1) {
            uint256 availableReward = calculateStakeReward(summary.stakes[s]);
            summary.stakes[s].claimable = availableReward;
            totalStakeAmount = totalStakeAmount + summary.stakes[s].amount;
        }
        // Assign calculate amount to summary
        summary.total_amount = totalStakeAmount;
        return summary;
    }
}