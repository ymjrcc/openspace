// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";

interface IWeth is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

interface IMyDex {
    function sellETH(address buyToken, uint256 minBuyAmount) external payable;
    function buyETH(address sellToken, uint256 sellAmount, uint256 minBuyAmount) external;
}

contract MyDex is IMyDex {
    IUniswapV2Router02 public immutable uniswapRouter;
    IUniswapV2Factory public immutable uniswapFactory;
    IWeth public immutable WETH;

    constructor(address _uniswapRouter, address _uniswapFactory) {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        uniswapFactory = IUniswapV2Factory(_uniswapFactory);
        WETH = IWeth(uniswapRouter.WETH());
    }

    function sellETH(address buyToken, uint256 minBuyAmount) external payable override {
        require(msg.value > 0, "Must send ETH");

        // 将 ETH 包装为 WETH
        WETH.deposit{value: msg.value}();

        // 批准 Router 使用 WETH
        WETH.approve(address(uniswapRouter), msg.value);

        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = buyToken;

        uint[] memory amounts = uniswapRouter.swapExactTokensForTokens(
            msg.value,       // uint amountIn
            minBuyAmount,  // uint amountOutMin
            path,            // address[] calldata path
            msg.sender,      // address to
            block.timestamp  // uint deadline
        );

        emit ETHSold(msg.sender, buyToken, msg.value, amounts[1]);
    }

    function buyETH(address sellToken, uint256 sellAmount, uint256 minBuyAmount) external override {
        require(sellAmount > 0, "Must sell some tokens");

        IERC20(sellToken).transferFrom(msg.sender, address(this), sellAmount);
        IERC20(sellToken).approve(address(uniswapRouter), sellAmount);

        address[] memory path = new address[](2);
        path[0] = sellToken;
        path[1] = address(WETH);

        uint[] memory amounts = uniswapRouter.swapExactTokensForTokens(
            sellAmount,    // uint amountIn
            minBuyAmount,  // uint amountOutMin
            path,            // address[] calldata path
            address(this),   // address to
            block.timestamp  // uint deadline
        );

        // 将获得的 WETH 转换回 ETH 并发送给用户
        WETH.withdraw(amounts[1]);
        payable(msg.sender).transfer(amounts[1]);

        emit ETHBought(msg.sender, sellToken, sellAmount, amounts[1]);
    }

    // 用于接收 ETH
    receive() external payable {}

    // 安全函数：取回误转入的 ETH
    function rescueETH() external {
        payable(msg.sender).transfer(address(this).balance);
    }

    // 安全函数：取回误转入的代币
    function rescueTokens(address token) external {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, balance);
    }

    event ETHSold(address indexed user, address indexed buyToken, uint256 ethAmount, uint256 tokenAmount);
    event ETHBought(address indexed user, address indexed sellToken, uint256 tokenAmount, uint256 ethAmount);
}