// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/UniswapV2Factory.sol";
import "../src/UniswapV2Router02.sol";
import "../src/UniswapV2Pair.sol";
import "../src/WETH9.sol";
import "../src/MyDex.sol";
import "../src/ERC20.sol";

contract RNToken is ERC20 {
    constructor() ERC20("RN Token", "RNT", 18) {
        _mint(msg.sender, 1000000 * 10**18);
    }
}

contract UniswapV2AndMyDexTest is Test {
    UniswapV2Factory public factory;
    UniswapV2Router02 public router;
    WETH9 public weth;
    RNToken public rnt;
    UniswapV2Pair public pair;
    MyDex public myDex;

    address public alice = address(0x1);
    address public bob = address(0x2);

    function setUp() public {
        // Deploy contracts
        weth = new WETH9();
        factory = new UniswapV2Factory(address(this));
        router = new UniswapV2Router02(address(factory), address(weth));
        rnt = new RNToken();
        myDex = new MyDex(address(router), address(factory));

        // Create pair
        factory.createPair(address(rnt), address(weth));
        pair = UniswapV2Pair(factory.getPair(address(rnt), address(weth)));

        // Fund accounts
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        rnt.transfer(alice, 10000 * 10**18);
        rnt.transfer(bob, 10000 * 10**18);
    }

    function testAddLiquidity() public {
        vm.startPrank(alice);
        rnt.approve(address(router), 1000 * 10**18);
        router.addLiquidityETH{value: 5 ether}(
            address(rnt),
            1000 * 10**18,
            0,
            0,
            alice,
            block.timestamp
        );
        vm.stopPrank();

        assertEq(pair.balanceOf(alice) > 0, true, "Liquidity not added");
    }

    function testRemoveLiquidity() public {
        // First add liquidity
        testAddLiquidity();

        uint liquidity = pair.balanceOf(alice);
        vm.startPrank(alice);
        pair.approve(address(router), liquidity);
        router.removeLiquidityETH(
            address(rnt),
            liquidity,
            0,
            0,
            alice,
            block.timestamp
        );
        vm.stopPrank();

        assertEq(pair.balanceOf(alice), 0, "Liquidity not fully removed");
    }

    function testSwapRNTForETHUsingMyDex() public {
        // First add liquidity
        testAddLiquidity();

        vm.startPrank(bob);
        uint256 bobEthBalanceBefore = bob.balance;
        uint256 swapAmount = 100 * 10**18;

        rnt.approve(address(myDex), swapAmount);
        myDex.buyETH(address(rnt), swapAmount, 0);

        vm.stopPrank();

        assertGt(bob.balance, bobEthBalanceBefore, "ETH not received");
    }

    function testSwapETHForRNTUsingMyDex() public {
        // First add liquidity
        testAddLiquidity();

        vm.startPrank(bob);
        uint256 bobRntBalanceBefore = rnt.balanceOf(bob);
        uint256 swapAmount = 1 ether;

        myDex.sellETH{value: swapAmount}(address(rnt), 0);

        vm.stopPrank();

        assertGt(rnt.balanceOf(bob), bobRntBalanceBefore, "RNT not received");
    }
}