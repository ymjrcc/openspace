// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AirdopMerkleNFTMarket.sol";
import "../src/MyToken.sol";
import "../src/MyNFT.sol";

contract AirdropMerkleNFTMarketTest is Test {
    AirdopMerkleNFTMarket public market;
    MyToken public token;
    MyNFT public nft;
    address public owner;
    address public user1;
    address public user2;
    uint256 public constant INITIAL_BALANCE = 1000e18;
    bytes32 public merkleRoot;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = vm.addr(uint256(keccak256(abi.encodePacked("user2"))));

        // Deploy token and NFT
        token = new MyToken(owner);
        nft = new MyNFT(owner);

        // Generate merkle root (simplified for testing)
        bytes32[] memory leaves = new bytes32[](2);
        leaves[0] = keccak256(abi.encodePacked(user1));
        leaves[1] = keccak256(abi.encodePacked(user2));
        merkleRoot = keccak256(abi.encodePacked(leaves[0], leaves[1]));

        // Deploy market
        market = new AirdopMerkleNFTMarket(address(token), merkleRoot);

        // Mint tokens and NFTs
        token.mint(user1, INITIAL_BALANCE);
        token.mint(user2, INITIAL_BALANCE);
        nft.safeMint(user1);
        nft.safeMint(user2);

        // Approve market to spend NFTs
        vm.prank(user1);
        nft.approve(address(market), 0);
        vm.prank(user2);
        nft.approve(address(market), 1);
    }

    function testListAndBuyNFT() public {
        uint256 listPrice = 100e18;
        
        // List NFT
        vm.prank(user1);
        market.list(address(nft), 0, listPrice);

        // Buy NFT
        vm.startPrank(user2);
        token.approve(address(market), listPrice);
        market.buyNFT(address(nft), 0);
        vm.stopPrank();

        // Check ownership and balances
        assertEq(nft.ownerOf(0), user2);
        assertEq(token.balanceOf(user1), INITIAL_BALANCE + listPrice);
        assertEq(token.balanceOf(user2), INITIAL_BALANCE - listPrice);
    }

    function testWhitelistClaimWithMulticall() public {
        uint256 listPrice = 100e18;
        
        // List NFT
        vm.prank(user1);
        market.list(address(nft), 0, listPrice);

        // Prepare permit data
        uint256 deadline = block.timestamp + 1 hours;
        bytes32 permitHash = keccak256(abi.encodePacked(
            "\x19\x01",
            token.DOMAIN_SEPARATOR(),
            keccak256(abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                user2,
                address(market),
                listPrice / 2,
                token.nonces(user2),
                deadline
            ))
        ));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256(keccak256(abi.encodePacked("user2"))), permitHash);

        // Prepare merkle proof (simplified for testing)
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = keccak256(abi.encodePacked(user1));

        // Prepare multicall data
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSelector(
            market.permitPrePay.selector,
            user2,
            address(market),
            listPrice / 2,
            deadline,
            v,
            r,
            s
        );
        data[1] = abi.encodeWithSelector(
            market.claimNFT.selector,
            address(nft),
            0,
            proof
        );

        // Execute multicall
        vm.prank(user2);
        market.multicall(data);

        // Check ownership and balances
        assertEq(nft.ownerOf(1), user2);
        assertEq(token.balanceOf(user1), INITIAL_BALANCE + listPrice / 2);
        assertEq(token.balanceOf(user2), INITIAL_BALANCE - listPrice / 2);
    }
}