// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {
    address public tokenAddress;
    address public factoryAddress;

    constructor(address _token) ERC20("S-UniSwap-V1", "SUNI") {
        require(_token != address(0));
        tokenAddress = _token;
        factoryAddress = msg.sender;
    }

    function addLiquidity(uint256 _tokenAmount) public payable returns (uint256) {
        require(msg.value > 0, "eth should be greater than 0");
        require(_tokenAmount > 0, "token should be greater than 0");

        IERC20 token = IERC20(tokenAddress);
        if (getTokenReserve() == 0) {
            token.transferFrom(msg.sender, address(this), _tokenAmount);
            _mint(msg.sender, msg.value);
            return msg.value;
        } else {
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 tokenReserve = token.balanceOf(address(this));
            uint256 tokenAmount = msg.value * tokenReserve / ethReserve;
            require(_tokenAmount >= tokenAmount, "insufficient token passed");
            token.transferFrom(msg.sender, address(this), tokenAmount);
            uint256 lpTokenAmount = msg.value * totalSupply() / ethReserve;
            _mint(msg.sender, lpTokenAmount);
            return lpTokenAmount;
        }
    }

    function removeLiquidity(uint256 _lpTokenAmount) public returns (uint256, uint256) {
        require(_lpTokenAmount > 0, "LP Token amount should be greater than 0");
        uint256 ethAmount = _lpTokenAmount * address(this).balance / totalSupply();
        uint256 tokenAmount = _lpTokenAmount * getTokenReserve() / totalSupply();
        _burn(msg.sender, _lpTokenAmount);
        payable(msg.sender).transfer(ethAmount);
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
        return (ethAmount, tokenAmount);
    }

    function getTokenReserve() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function _getAmount(uint256 _inputAmount, uint256 _inputReserve, uint256 _outputReserve)
        private
        pure
        returns (uint256)
    {
        require(_inputReserve >= 0 && _outputReserve >= 0);
        // We deduct 1% fee from _inputAmount.
        // Note that Solidity doesn't support floating-point calculation so the formula has to be tweaked a bit.
        return (_inputAmount * 99 * _outputReserve) / (_inputReserve * 100 + _inputAmount * 99);
    }

    function getTokenAmount(uint256 _ethSold) public view returns (uint256) {
        require(_ethSold > 0);
        return _getAmount(_ethSold, address(this).balance, getTokenReserve());
    }

    function getEthAmount(uint256 _tokenSold) public view returns (uint256) {
        require(_tokenSold > 0);
        return _getAmount(_tokenSold, getTokenReserve(), address(this).balance);
    }

    function ethToTokenSwap(uint256 _minAmount) public payable returns (uint256) {
        require(_minAmount >= 0);
        uint256 amount = _getAmount(msg.value, address(this).balance - msg.value, getTokenReserve());
        require(amount >= _minAmount, "output amount should be greater than min amount");
        IERC20(tokenAddress).transfer(msg.sender, amount);
        return amount;
    }

    function tokenToEthSwap(uint256 _tokenAmount, uint256 _minAmount) public returns (uint256) {
        require(_minAmount >= 0);
        uint256 amount = _getAmount(_tokenAmount, getTokenReserve(), address(this).balance);
        require(amount >= _minAmount, "output amount should be greater than min amount");
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokenAmount);
        payable(msg.sender).transfer(amount);
        return amount;
    }
}
