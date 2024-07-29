// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

contract MyToken is Initializable, ERC20Upgradeable, OwnableUpgradeable {

    uint256 public TOTAL_SUPPLY;
    uint256 public PER_MINT;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
      string memory _symbol, 
      uint _totalSupply, 
      uint256 _perMint,
      address owner
    ) initializer public {
        require(_totalSupply > 0, "Total supply must be greater than 0");
        require(_perMint > 0, "Per mint must be greater than 0");
        TOTAL_SUPPLY = _totalSupply;
        PER_MINT = _perMint;
        __ERC20_init(_symbol, _symbol);
        __Ownable_init(owner);
    }

    // owner 是 factory 代理合约的地址
    function mint(address to) public onlyOwner {
        require(totalSupply() + PER_MINT <= TOTAL_SUPPLY, "Total supply exceeded");
        _mint(to, PER_MINT);
    }
}