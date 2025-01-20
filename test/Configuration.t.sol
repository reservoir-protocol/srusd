// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

import {Savingcoin} from "src/Savingcoin.sol";

import {StablecoinMock} from "./StablecoinMock.sol";

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

contract ConfigurationTest is Test {
    Savingcoin srusd;
    StablecoinMock rusd;

    address eoa1 = vm.addr(1);
    address eoa2 = vm.addr(2);

    function setUp() external {
        rusd = new StablecoinMock("Reservoir Stablecoin Mock", "rUSDM");
        srusd = new Savingcoin(
            address(this),
            "Reservoir Savingcoin",
            "srUSD",
            rusd
        );

        srusd.grantRole(srusd.MANAGER(), address(this));

        srusd.setCap(type(uint256).max);
    }

    function testInitialState() external view {
        assertTrue(srusd.hasRole(0x00, address(this)));
        assertTrue(srusd.hasRole(srusd.MANAGER(), address(this)));

        assertEq(srusd.symbol(), "srUSD");
        assertEq(srusd.name(), "Reservoir Savingcoin");

        assertEq(srusd.decimals(), 18);
        assertEq(srusd.asset(), address(rusd));

        assertEq(srusd.totalAssets(), 0);
        assertEq(srusd.totalSupply(), 0);

        assertEq(srusd.lastTimestamp(), 1);

        assertEq(srusd.currentRate(), 0e27);
        assertEq(srusd.compoundFactor(), 1e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);
    }
}
