// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Bank {
    address public owner;
    mapping(address => uint256) public balances;
    address[3] public top3;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner!");
        _;
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable virtual {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;
        _updateTop3();
    }

    function _sort() private {
        for (uint8 i = 0; i < 3; i++) {
            for (uint8 j = i + 1; j < 3; j++) {
                if (balances[top3[i]] < balances[top3[j]]) {
                    address temp = top3[i];
                    top3[i] = top3[j];
                    top3[j] = temp;
                }
            }
        }
    }

    function _updateTop3() private {
        // 如果存款人在 top3 里，直接排序
        if (
            msg.sender == top3[0] ||
            msg.sender == top3[1] ||
            msg.sender == top3[2]
        ) {
            _sort();
        // 如果存款人不在 top3 里，且其金额比第三名高，将第三名更新后排序
        } else if (balances[msg.sender] > balances[top3[2]]) {
            top3[2] = msg.sender;
            _sort();
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = owner.call{value: balance}("");
        if (!success) {
            revert("failed!");
        }
    }
}
