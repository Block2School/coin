// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract MultiOwnable {
    // The manager is the address that can add and remove owners
    // owners is the list of addresses that can call onlyOwner functions
    address public manager;
    address[] public owners;

    mapping(address => bool) public ownerByAddress;

    event SetOwner(address[] owners);
    event AddOwner(address owner);
    event RemoveOwner(address owner);

    modifier onlyOwner() {
        require(
            ownerByAddress[msg.sender] == true || msg.sender == manager,
            "Only owner can call this function."
        );
        _;
    }

    constructor() {
        manager = msg.sender;
    }

    function setOwners(address[] memory _owners) public {
        require(msg.sender == manager, "Only manager can call this function.");
        _setOwners(_owners);
    }

    function _setOwners(address[] memory _owners) internal {
        for (uint256 i = 0; i < owners.length; i++) {
            ownerByAddress[owners[i]] = false;
        }

        for (uint256 j = 0; j < _owners.length; j++) {
            ownerByAddress[_owners[j]] = true;
        }
        owners = _owners;
        emit SetOwner(_owners);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getManager() public view returns (address) {
        return manager;
    }

    function setManager(address _manager) public {
        require(msg.sender == manager, "Only manager can call this function.");
        manager = _manager;
    }

    function isOwner(address _address) public view returns (bool) {
        return ownerByAddress[_address];
    }

    function removeOwner(address _address) public {
        require(msg.sender == manager, "Only manager can call this function.");
        require(ownerByAddress[_address] == true, "Address is not an owner.");
        ownerByAddress[_address] = false;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == _address) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                break;
            }
        }
    }

    function addOwner(address _address) public {
        require(msg.sender == manager, "Only manager can call this function.");
        require(
            ownerByAddress[_address] == false,
            "Address is already an owner."
        );
        ownerByAddress[_address] = true;
        owners.push(_address);
        emit AddOwner(_address);
    }
}
