// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./ERC20.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts/contracts/proxy/Clones.sol";

contract TokenFactory is Initializable, OwnableUpgradeable {

    mapping(address => uint) public tokenMintPrices;
    address public implementationAddress;
    address[] public clones;

    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __Ownable_init(msg.sender);
    }

    function reinitialize(uint8 version) reinitializer(version) public {
        __Ownable_init(msg.sender);
    }

    function initialize(address _implementationAddress) initializer public {
        implementationAddress = _implementationAddress;
        __Ownable_init(msg.sender);
    }

    function setImplementationAddress(address _implementationAddress) public onlyOwner {
        implementationAddress = _implementationAddress;
    }

    // 该方法用来创建 ERC20 token，（模拟铭文的 deploy）， 
    // symbol 表示 Token 的名称，totalSupply 表示可发行的数量，
    // perMint 用来控制每次发行的数量，用于控制mintInscription函数每次发行的数量
    // price 表示发行每个 token 需要支付的费用
    function deployInscription(
        string memory symbol, 
        uint totalSupply, 
        uint perMint,
        uint price
    ) public {
        require(price > 0, "Price must be greater than 0");
        address clone = Clones.clone(implementationAddress);
        MyToken(clone).initialize(symbol, totalSupply, perMint, msg.sender);
        clones.push(clone);
        tokenMintPrices[address(clone)] = price;
    }

    // 用来发行 ERC20 token，每次调用一次，发行perMint指定的数量。
    function mintInscription(address tokenAddr) public payable{
        // require(bytes(tokens[tokenAddr]).length > 0, "Token not found");
        require(msg.value >= tokenMintPrices[tokenAddr] * MyToken(tokenAddr).PER_MINT(), "Insufficient funds");
        MyToken(tokenAddr).mint(msg.sender);
    }

}