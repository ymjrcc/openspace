// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Bank {
    address public owner;
    mapping(address => uint256) public balances;
    struct Contributor {
        address addr;
        uint256 amount;
    }
    // 定义数组记录所有存款者，方便排序
    Contributor[] public contributors;

    constructor() {
        // 初始化管理员账户
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner!");
        _;
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
        bool isExisting = false;
        for (uint256 i = 0; i < contributors.length; i++) {
            // 如果存款者存在，在数组中更新该存款者信息
            if (msg.sender == contributors[i].addr) {
                contributors[i].amount += msg.value;
                isExisting = true;
                break;
            }
        }
        if (!isExisting) {
            // 如果存款者不存在，在数组中新增该存款者信息
            contributors.push(Contributor(msg.sender, msg.value));
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = owner.call{value: balance}("");
        if (!success) {
            revert("failed!");
        }
    }

    function getTop3() public view returns (Contributor[] memory) {
        require(contributors.length > 0, "No contributors!");
        // 对数组进行排序
        Contributor[] memory sortedContributors = contributors;
        for (uint i = 0; i < sortedContributors.length - 1; i++) {
            for (uint j = 0; j < sortedContributors.length - i - 1; j++) {
                if (
                    sortedContributors[j].amount <
                    sortedContributors[j + 1].amount
                ) {
                    Contributor memory temp = sortedContributors[j];
                    sortedContributors[j] = sortedContributors[j + 1];
                    sortedContributors[j + 1] = temp;
                }
            }
        }
        // 取出前三名（不足 3 名则全部返回）
        Contributor[] memory topContributors = new Contributor[](3);
        for (uint i = 0; i < 3; i++) {
            if (i < sortedContributors.length) {
                topContributors[i] = sortedContributors[i];
            }
        }
        return topContributors;
    }
}
