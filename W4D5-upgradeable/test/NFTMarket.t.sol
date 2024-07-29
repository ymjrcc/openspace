// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {NFTMarketV1} from "../src/NFTMarket.sol";
import {NFTMarketV2} from "../src/NFTMarketV2.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockERC721 is ERC721 {
    constructor() ERC721("MockNFT", "MNFT") {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}

contract MockERC20 is ERC20 {
    constructor() ERC20("MockToken", "MTK") {
        _mint(msg.sender, 1000000 * 10**18);
    }
}

contract NFTMarketTest is Test {
    NFTMarketV1 public marketV1;
    NFTMarketV2 public marketV2;
    ERC1967Proxy public proxy;
    MockERC721 public mockNFT;
    MockERC20 public mockToken;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        // Deploy mock contracts
        mockNFT = new MockERC721();
        mockToken = new MockERC20();

        // Deploy NFTMarketV1 implementation
        marketV1 = new NFTMarketV1();

        // Deploy proxy and initialize with V1
        bytes memory initData = abi.encodeWithSelector(NFTMarketV1.initialize.selector, address(mockToken));
        proxy = new ERC1967Proxy(address(marketV1), initData);

        // Mint NFT and approve market
        mockNFT.mint(user1, 1);
        vm.prank(user1);
        mockNFT.approve(address(proxy), 1);

        // Give tokens to user2
        mockToken.transfer(user2, 1000 * 10**18);
    }

    function testUpgrade() public {
        NFTMarketV1 proxyAsV1 = NFTMarketV1(address(proxy));

        // List NFT using V1
        vm.prank(user1);
        proxyAsV1.list(address(mockNFT), 1, 100 * 10**18);

        // Check listing
        (address _owner, uint256 price) = proxyAsV1.nftList(address(mockNFT), 1);
        assertEq(_owner, user1);
        assertEq(price, 100 * 10**18);

        // Deploy V2 implementation
        marketV2 = new NFTMarketV2();

        // Upgrade to V2
        vm.prank(owner);
        UUPSUpgradeable(address(proxy)).upgradeToAndCall(address(marketV2), "");

        NFTMarketV2 proxyAsV2 = NFTMarketV2(address(proxy));

        // Check if state is preserved after upgrade
        (owner, price) = proxyAsV2.nftList(address(mockNFT), 1);
        assertEq(owner, user1);
        assertEq(price, 100 * 10**18);

        // Prepare EIP712 signature
        bytes32 DOMAIN_SEPARATOR = proxyAsV2.DOMAIN_SEPARATOR();
        bytes32 LIST_TYPEHASH = keccak256("List(address nftAddr,uint256 tokenId,uint256 price)");
        
        bytes32 structHash = keccak256(abi.encode(
            LIST_TYPEHASH,
            address(mockNFT),
            0,
            price
        ));


        // Test new functionality in V2
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256(keccak256(abi.encodePacked(user1))), digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        mockNFT.mint(user1, 2);
        vm.prank(user1);
        mockNFT.setApprovalForAll(address(proxy), true);

        vm.prank(user2);
        proxyAsV2.listWithSignature(address(mockNFT), 2, 200 * 10**18, signature);

        // Check new listing
        (owner, price) = proxyAsV2.nftList(address(mockNFT), 2);
        assertEq(owner, user1);
        assertEq(price, 200 * 10**18);

        // Test buying NFT
        vm.prank(user2);
        mockToken.approve(address(proxy), 200 * 10**18);
        proxyAsV2.buyNFT(address(mockNFT), 2);

        assertEq(mockNFT.ownerOf(2), user2);
    }
}