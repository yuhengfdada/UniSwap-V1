// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Exchange} from "../src/Exchange.sol";
import {Token} from "../src/Token.sol";

contract ExchangeTest is Test {
    Token public token;
    Exchange public exchange;

    function setUp() public {
        token = new Token("MyToken", "MTK", 1e36);
        exchange = new Exchange(address(token));
    }

    function test_AddLiquidity() public {
        token.approve(address(exchange), 2000e18);
        exchange.addLiquidity{value: 1000 ether}(2000e18);
        assertEq(exchange.getTokenReserve(), 2000e18);

        token.approve(address(exchange), 1000e18);
        exchange.addLiquidity{value: 500 ether}(1000e18);
        assertEq(exchange.getTokenReserve(), 3000e18);

        token.approve(address(exchange), 1000e18);
        exchange.addLiquidity{value: 100 ether}(1000e18);
        assertEq(exchange.getTokenReserve(), 3200e18);

        vm.expectRevert("insufficient token passed");
        exchange.addLiquidity{value: 1000 ether}(1000e18);
    }

    function test_GetAmount() public {
        token.approve(address(exchange), 2000e18);
        exchange.addLiquidity{value: 1000 ether}(2000e18);
        assertEq(exchange.getTokenAmount(1e18), 1978041738678708079);
    }

    receive() external payable {}

    function test_tokenToEthTransfer() public {
        token.approve(address(exchange), 2000e18);
        exchange.addLiquidity{value: 1000 ether}(2000e18);
        assertEq(exchange.getTokenAmount(1e18), 1978041738678708079);

        token.approve(address(exchange), 2e18);
        uint256 currentBalance = address(this).balance;
        exchange.tokenToEthSwap(2e18, 1);
        assertEq(address(this).balance, currentBalance + 989020869339354039);
    }

    function test_tokenToEthTransfer_outputLessThanMinAmount() public {
        token.approve(address(exchange), 2000e18);
        exchange.addLiquidity{value: 1000 ether}(2000e18);
        assertEq(exchange.getTokenAmount(1e18), 1978041738678708079);

        token.approve(address(exchange), 2e18);

        vm.expectRevert("output amount should be greater than min amount");
        exchange.tokenToEthSwap(2e18, 1 ether);
    }

    function test_provideLiquidity() public {
        token.approve(address(exchange), 200e18);
        uint256 lpTokenAmount = exchange.addLiquidity{value: 100 ether}(200e18);
        address user = vm.addr(1);
        vm.deal(user, 100 ether);
        vm.prank(user);
        exchange.ethToTokenSwap{value: 10 ether}(18e18);
        console.log(token.balanceOf(user));
        console.log(exchange.getTokenReserve());
        console.log(address(exchange).balance);
        vm.stopPrank();
        uint256 ethAmount;
        uint256 tokenAmount;
        (ethAmount, tokenAmount) = exchange.removeLiquidity(lpTokenAmount);
        console.log("got eth: %s", ethAmount);
        console.log("got token: %s", tokenAmount);
    }
}
