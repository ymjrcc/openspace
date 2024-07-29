// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./ERC20.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

contract TokenFactory is Initializable, OwnableUpgradeable {

    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __Ownable_init(msg.sender);
    }

    // 该方法用来创建 ERC20 token，（模拟铭文的 deploy）， 
    // symbol 表示 Token 的名称，totalSupply 表示可发行的数量，
    // perMint 用来控制每次发行的数量，用于控制mintInscription函数每次发行的数量
    function deployInscription(
      string memory symbol, 
      uint totalSupply, 
      uint perMint
    ) public {
        MyToken token = new MyToken();
        token.initialize(symbol, totalSupply, perMint, msg.sender);
    }

    // 用来发行 ERC20 token，每次调用一次，发行perMint指定的数量。
    function mintInscription(address tokenAddr) public {
        // require(bytes(tokens[tokenAddr]).length > 0, "Token not found");
        MyToken(tokenAddr).mint(msg.sender);
    }

}