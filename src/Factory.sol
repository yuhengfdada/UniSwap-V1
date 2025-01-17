// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Exchange.sol";

contract Factory {
    mapping(address => address) public exchanges;

    function createExchange(address _tokenAddress) public returns (address) {
        require(_tokenAddress != address(0));
        require(exchanges[_tokenAddress] == address(0));
        Exchange e = new Exchange(_tokenAddress);
        exchanges[_tokenAddress] = address(e);
        return address(e);
    }
}
