// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";

import {IERC20Metadata} from "openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol";

import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

import {console} from "forge-std/console.sol";

contract Migration {

    IERC20 asset;
    IERC4626 vault;
    
    IERC20 token;

    constructor(
        address vault_,
        address token_
    ) {
        vault = IERC4626(vault_);

        token = IERC20(token_);
    }

    // function migrate(uint256 amount) external {
    //     require(token.transferFrom(msg.sender, address(this), amount), "transfer failed");
        
    //     // redeem srusd against saving module

    //     uint256 shares = vault.deposit( , msg.sender); // return the shares

    //     // ????
    // }
}
