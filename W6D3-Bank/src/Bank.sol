// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Bank {
    mapping(address => uint256) public balances;
    mapping(address => address) _nextUsers;
    uint256 public totalUsers;
    address private constant GUARD = address(1);

    constructor() {
        _nextUsers[GUARD] = GUARD;
    }

    function _add(address user, uint256 balance, address candidateUser) private {
        require(_nextUsers[user] == address(0), "User already exists");
        require(_nextUsers[candidateUser] != address(0), "Candidate user does not exist");
        require(_verifyIndex(candidateUser, balance, _nextUsers[candidateUser]), "Invalid index");
        _nextUsers[user] = _nextUsers[candidateUser];
        _nextUsers[candidateUser] = user;
        totalUsers++;
    }

    function _remove(address user, address candidateUser) private {
        require(_nextUsers[user] != address(0), "User does not exist");
        require(_isPrevUser(user, candidateUser), "User is not the previous user");
        _nextUsers[candidateUser] = _nextUsers[user];
        _nextUsers[user] = address(0);
        totalUsers--;
    }

    function _update(address user, uint256 balance, address oldCandidateUser, address newCandidateUser) private {
        require(_nextUsers[user] != address(0), "User does not exist");
        require(_nextUsers[oldCandidateUser] != address(0), "Old candidate user does not exist");
        require(_nextUsers[newCandidateUser] != address(0), "New candidate user does not exist");
        if(oldCandidateUser == newCandidateUser){
            require(_isPrevUser(user, oldCandidateUser), "User is not the previous user");
            require(_verifyIndex(newCandidateUser, balance, _nextUsers[user]), "Invalid index");
        } else {
            _remove(user, oldCandidateUser);
            _add(user, balance, newCandidateUser);
        }
    }

    function _verifyIndex(address prevUser, uint256 newBalance, address nextUser) private view returns (bool) {
        return (prevUser == GUARD || balances[prevUser] >= newBalance) && 
          (nextUser == GUARD || newBalance > balances[nextUser]);
    }

    function _isPrevUser(address user, address prevUser) private view returns(bool) {
    return _nextUsers[prevUser] == user;
  }

    function deposit(address oldCandidateUser, address newCandidateUser) public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        address user = msg.sender;
        uint256 amount = msg.value;
        balances[user] += amount;
        if(_nextUsers[user] == address(0)) {
            _add(user, balances[user], oldCandidateUser);
        } else {
            _update(user, balances[user], oldCandidateUser, newCandidateUser);
        }
        emit Deposit(user, amount);
    }

    function withdraw(uint256 amount, address oldCandidateUser, address newCandidateUser) public {
        require(amount > 0, "Withdraw amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        address user = msg.sender;
        balances[user] -= amount;
        _update(user, balances[user], oldCandidateUser, newCandidateUser);
        (bool success, ) = payable(user).call{value: amount}("");
        require(success, "Transfer failed");
        emit Withdraw(user, amount);
    }

    function getTopTenUsers() public view returns (address[10] memory, uint256[10] memory) {
        address[10] memory topUsers;
        uint256[10] memory topBalances;
        address currentUser = _nextUsers[GUARD];
        uint256 count = 0;

        while (currentUser != GUARD && count < 10) {
            topUsers[count] = currentUser;
            topBalances[count] = balances[currentUser];
            currentUser = _nextUsers[currentUser];
            count++;
        }

        return (topUsers, topBalances);
    }

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
}
