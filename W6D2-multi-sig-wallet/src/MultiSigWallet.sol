// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MultiSigWallet {
    
    address[] public owners;
    mapping (address=>bool) public isOwner;
    uint128 public ownersCountForConfirmation;

    struct Transaction {
        bool executed;          // 是否已执行
        uint128 Confirmations;  // 已获得的确认数
        address destination;    // 目标地址
        uint256 value;          // 交易金额
        bytes data;             // 交易数据
    }
    Transaction[] public transactions;

    // 交易 ID => 持有人 => 是否已确认
    mapping (uint256=>mapping (address=>bool)) public isConfirmed;

    constructor(
        address[] memory _owners,
        uint128 _ownersCountForConfirmation
    ) {
        require(_owners.length > 0, "Owners required");
        require(_ownersCountForConfirmation > 0, "Owners count for confirmation required");
        require(_ownersCountForConfirmation <= _owners.length, "Owners count for confirmation must be less than or equal to owners count");
        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Owner exists");
            isOwner[owner] = true;
            owners.push(owner);
        }
        ownersCountForConfirmation = _ownersCountForConfirmation;
    }

    // 发起交易
    function submitTransaction(address _destination, uint256 _value, bytes calldata _data)  public onlyOwner{
        transactions.push(
            Transaction({
                executed: false,
                Confirmations: 0,
                destination: _destination,
                value: _value,
                data: _data
            })
        );

        emit TransactionSubmitted(transactions.length - 1, msg.sender, _destination, _value, _data);
    }

    // 确认交易
    function confirmTransaction(uint256 _txIndex) public onlyOwner {
        require(_txIndex < transactions.length, "Invalid transaction index");
        require(!isConfirmed[_txIndex][msg.sender], "Transaction already confirmed");
        require(!transactions[_txIndex].executed, "Transaction already executed");

        isConfirmed[_txIndex][msg.sender] = true;
        transactions[_txIndex].Confirmations++;

        emit TransactionConfirmed(_txIndex, msg.sender);
    }

    // 执行交易
    function executeTransaction(uint256 _txIndex) public {
        require(_txIndex < transactions.length, "Invalid transaction index");
        require(!transactions[_txIndex].executed, "Transaction already executed");
        require(transactions[_txIndex].Confirmations >= ownersCountForConfirmation, "Not enough confirmations");

        Transaction storage transaction = transactions[_txIndex];
        transaction.executed = true;
        (bool success, ) = transaction.destination.call{value: transaction.value}(transaction.data);
        require(success, "Transaction execution failed");

        emit TransactionExecuted(_txIndex);
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not owner");
        _;
    }

    event Deposit(address indexed sender, uint256 value);
    event TransactionSubmitted(
        uint256 indexed txIndex, 
        address indexed owner, 
        address indexed destination,
        uint256 value,
        bytes data
    );
    event TransactionConfirmed(uint256 indexed txIndex, address indexed owner);
    event TransactionExecuted(uint256 indexed txIndex);
}