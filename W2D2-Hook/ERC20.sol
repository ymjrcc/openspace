// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ITokenRecipient {
    function tokensReceived(
        address from,
        uint256 amount
    ) external returns (bool);
}

interface INFTMarket {
    function tokensReceived(
        address from,
        address nftAddress,
        uint256 tokenId,
        uint256 ownerAddress,
        uint256 nftPrice
    ) external returns (bool);
}

contract MyToken is ERC20, Ownable {
    constructor() ERC20("MyToken", "MTK") Ownable(msg.sender) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // 转入 token 到 TokenBank 实现存款
    function transferWithCallback(
        address recipient,
        uint256 amount
    ) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        if (recipient.code.length > 0) {
            bool rv = ITokenRecipient(recipient).tokensReceived(
                msg.sender,
                amount
            );
            require(rv, "No tokensReceived");
        }
        return true;
    }

    // 使用ERC20扩展中的回调函数来购买某个 NFT ID
    function transferAndCallBuyNFT(
        address nftAddress,
        uint256 tokenId,
        uint256 ownerAddress,
        uint256 nftPrice
    ) external returns (bool) {
        _transfer(msg.sender, ownerAddress, nftPrice);
        if (nftAddress.code.length > 0) {
            bool rv = INFTMarket(nftAddress).tokensReceived(
                msg.sender,
                nftAddress,
                tokenId,
                ownerAddress,
                nftPrice
            );
            require(rv, "No tokensReceived");
        }
    }
}
