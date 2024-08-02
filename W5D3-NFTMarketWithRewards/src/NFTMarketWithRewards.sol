// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "openzeppelin-contracts/contracts/interfaces/IERC721.sol";

contract NFTMarketWithRewards {
    
    struct Order {
        address owner;
        uint256 price;
    }
    // NFTAddress => tokenId => Order
    mapping(address => mapping(uint256 => Order)) public nftList;
    
    // 总的质押 ETH 的数量
    uint256 public totalStaked;
    // 每单位质押 ETH 的累积奖励
    uint256 public rewardPerETHStored;
    // 每个用户质押 ETH 的数量
    mapping(address => uint256) public userStakeAmount;
    // 每个用户待领取的奖励
    mapping(address => uint256) public userRewardToClaim;
    // 每个用户上次领取奖励时的 每单位质押 ETH 的累积奖励
    mapping(address => uint256) public userRewardPerETHPaid;

    function list(address _nftAddr, uint256 _tokenId, uint256 _price) public {
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.getApproved(_tokenId) == address(this), "Not approved");
        require(_price > 0, "The price must be greater than 0");
        Order storage _order = nftList[_nftAddr][_tokenId];
        _order.owner = msg.sender;
        _order.price = _price;
        _nft.transferFrom(msg.sender, address(this), _tokenId);
        emit List(msg.sender, _nftAddr, _tokenId, _price);
    }

    function buyNFT(address _nftAddr, uint256 _tokenId) public payable {
        Order memory _order = nftList[_nftAddr][_tokenId];
        require(_order.price > 0, "The price must be greater than 0");
        require(msg.value == _order.price, "The price is not correct");
        // 处理 nft 交易
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "NFT is not on sell");
        delete nftList[_nftAddr][_tokenId];
        _nft.transferFrom(address(this), msg.sender, _tokenId);
        // 抽取 1% 的手续费
        uint256 fee = _order.price * 10 / 1000;

        if(totalStaked > 0) {
            rewardPerETHStored += fee * 1e18 / totalStaked;
        }

        emit FeesCollected(fee);
        // 将剩余的钱转给卖家
        (bool success, ) = payable(_order.owner).call{value: _order.price - fee}("");
        require(success, "Transfer failed");
        emit BuyNFT(msg.sender, _nftAddr, _tokenId, _order.price);
    }
    
    function _updateReward(address account) internal {
        require(account != address(0), "Invalid account");
        // 更新该用户待领取奖励
        userRewardToClaim[account] += userStakeAmount[account] * (rewardPerETHStored - userRewardPerETHPaid[account]) / 1e18;
        // 更新该用户的累积奖励
        userRewardPerETHPaid[account] = rewardPerETHStored;
    }

    function stake() public payable {
        _updateReward(msg.sender);
        userStakeAmount[msg.sender] += msg.value;
        totalStaked += msg.value;
        emit Staked(msg.sender, msg.value);
    }

    function unstake(uint256 amount) public {
        require(userStakeAmount[msg.sender] >= amount, "Insufficient staked amount");
        _updateReward(msg.sender);
        userStakeAmount[msg.sender] -= amount;
        totalStaked -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        emit Unstaked(msg.sender, amount);
    }

    function claimReward() public {
        _updateReward(msg.sender);
        uint256 reward = userRewardToClaim[msg.sender];
        require(reward > 0, "No rewards to claim");
        userRewardToClaim[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: reward}("");
        require(success, "Transfer failed");
        emit RewardClaimed(msg.sender, reward);
    }

    event List(
        address indexed seller,
        address indexed nftAddr,
        uint256 indexed tokenId,
        uint256 price
    );
    event BuyNFT(
        address indexed buyer,
        address indexed nftAddr,
        uint256 indexed tokenId,
        uint256 price
    );

    // 当用户质押ETH时触发
    event Staked(address indexed user, uint256 amount);
    // 当用户取消质押ETH时触发
    event Unstaked(address indexed user, uint256 amount);
    // 当收取交易手续费时触发
    event FeesCollected(uint256 amount);
    // 当用户领取奖励时触发
    event RewardClaimed(address indexed user, uint256 amount);
}
