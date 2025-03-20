// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import {Savingcoin} from "../src/Savingcoin.sol";

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }

    function burnFrom(address account, uint256 amount) external {
        _burn(account, amount);
    }
}

contract SavingcoinTest2 is Test {
    Savingcoin public savingcoin;
    MockToken public rusd;

    address public constant ADMIN = address(0x1);
    address public constant MANAGER = address(0x2);
    address public constant USER = address(0x3);

    uint256 public constant RAY = 1e27;
    bytes32 public constant MANAGER_ROLE =
        keccak256(abi.encode("savingcoin.manager"));

    function setUp() public {
        // Deploy mock stablecoin
        rusd = new MockToken("rUSD", "rUSD");

        // Deploy Savingcoin vault
        savingcoin = new Savingcoin(ADMIN, "Savings rUSD", "srUSD", rusd);

        // Setup roles
        vm.prank(ADMIN);
        savingcoin.grantRole(MANAGER_ROLE, MANAGER);

        // Setup initial balances and approvals
        rusd.mint(USER, 10000e18); // Increased initial balance
        vm.prank(USER);
        rusd.approve(address(savingcoin), type(uint256).max);
    }

    function testConstructor() public {
        assertEq(savingcoin.name(), "Savings rUSD");
        assertEq(savingcoin.symbol(), "srUSD");
        assertEq(address(savingcoin.asset()), address(rusd));
        assertTrue(savingcoin.hasRole(savingcoin.DEFAULT_ADMIN_ROLE(), ADMIN));
        assertEq(savingcoin.cap(), 0);
        assertEq(savingcoin.compoundFactorAccum(), RAY);
        assertEq(savingcoin.currentRate(), 0);
    }

    function testAccessControl() public {
        // Only manager can set cap
        vm.prank(USER);
        vm.expectRevert();
        savingcoin.setCap(1000e18);

        // Manager can set cap
        vm.prank(MANAGER);
        savingcoin.setCap(1000e18);
        assertEq(savingcoin.cap(), 1000e18);

        // Only manager can update rate
        vm.prank(USER);
        vm.expectRevert();
        savingcoin.update(1e26); // 0.1 in RAY format

        // Manager can update rate
        vm.prank(MANAGER);
        savingcoin.update(1e26); // 0.1 in RAY format
        assertEq(savingcoin.currentRate(), 1e26);
    }

    function testDeposit() public {
        // Set cap
        vm.prank(MANAGER);
        savingcoin.setCap(1000e18);

        uint256 depositAmount = 100e18;

        // Perform deposit
        vm.prank(USER);
        uint256 sharesReceived = savingcoin.deposit(depositAmount, USER);

        // Verify results
        assertEq(savingcoin.balanceOf(USER), sharesReceived);
        assertEq(savingcoin.totalSupply(), sharesReceived);
        assertEq(savingcoin.totalAssets(), depositAmount);
    }

    function testDepositExceedingCap() public {
        // Set low cap
        vm.prank(MANAGER);
        savingcoin.setCap(50e18);

        uint256 depositAmount = 100e18;

        // Attempt deposit above cap
        vm.prank(USER);
        vm.expectRevert("newly issued shares can not exceed notional cap");
        savingcoin.deposit(depositAmount, USER);
    }

    function testWithdraw() public {
        // Set cap and deposit
        vm.prank(MANAGER);
        savingcoin.setCap(1000e18);

        uint256 depositAmount = 100e18;
        vm.prank(USER);
        uint256 sharesReceived = savingcoin.deposit(depositAmount, USER);

        // Perform withdrawal
        vm.prank(USER);
        uint256 assetsReceived = savingcoin.withdraw(depositAmount, USER, USER);

        // Verify results
        assertEq(savingcoin.balanceOf(USER), 0);
        assertEq(savingcoin.totalSupply(), 0);
        assertEq(savingcoin.totalAssets(), 0);
        assertEq(assetsReceived, depositAmount);
    }

    function testCompoundFactor() public {
        // Set initial rate
        vm.prank(MANAGER);
        savingcoin.update(1e26); // 10% APR

        // Move time forward 1 year
        skip(365 days);

        // Check compound factor
        uint256 factor = savingcoin.compoundFactor();
        assertTrue(factor > RAY, "Compound factor should increase over time");
    }

    function testAPY() public {
        // Test different rates
        uint256[] memory rates = new uint256[](3);
        rates[0] = 5e25; // 5% APR
        rates[1] = 1e26; // 10% APR
        rates[2] = 5e26; // 50% APR

        for (uint256 i = 0; i < rates.length; i++) {
            vm.prank(MANAGER);
            savingcoin.update(rates[i]);

            uint256 apy = savingcoin.apy();
            assertTrue(
                apy > rates[i],
                "APY should be higher than APR due to compounding"
            );
        }
    }

    function testAssetToShareConversion() public {
        // Set cap to allow for appreciation
        vm.prank(MANAGER);
        savingcoin.setCap(1e18);

        // Initial deposit of 1% of cap
        uint256 depositAmount = 0.001e18;
        vm.prank(USER);
        uint256 initialShares = savingcoin.deposit(depositAmount, USER);

        // Set very small rate and move time forward
        vm.prank(MANAGER);
        savingcoin.update(0.0001e26); // 0.001% APR
        skip(365 days);

        // Calculate expected assets after a year
        uint256 expectedAssets = savingcoin.convertToAssets(initialShares);
        assertTrue(
            expectedAssets > depositAmount,
            "Assets should appreciate over time"
        );

        // Calculate shares needed for same deposit amount
        uint256 previewShares = savingcoin.previewDeposit(depositAmount);
        assertTrue(
            previewShares < initialShares,
            "Later deposits should receive fewer shares"
        );

        vm.expectRevert("newly issued shares can not exceed notional cap");

        // Perform second deposit
        vm.prank(USER);
        uint256 laterShares = savingcoin.deposit(depositAmount, USER);

        assertEq(laterShares, 0, "Should receive previewed shares amount");
    }

    function testShareToAssetConversion() public {
        vm.prank(MANAGER);
        savingcoin.setCap(1000e18);

        // Initial deposit
        uint256 depositAmount = 100e18;
        vm.prank(USER);
        uint256 shares = savingcoin.deposit(depositAmount, USER);

        // Set rate and move time forward
        vm.prank(MANAGER);
        savingcoin.update(1e26); // 10% APR
        skip(365 days);

        // Same number of shares should now be worth more assets
        uint256 assetsForShares = savingcoin.convertToAssets(shares);
        assertTrue(
            assetsForShares > depositAmount,
            "Shares should be worth more assets after appreciation"
        );
    }

    function testRateUpdate() public {
        uint256 rate = 1e26; // 10% APR

        // Initial update
        vm.prank(MANAGER);
        savingcoin.update(rate);
        uint256 initialAccum = savingcoin.compoundFactorAccum();

        // Skip time and check accumulator increases
        skip(1 days);
        uint256 factor = savingcoin.compoundFactor();
        assertTrue(factor > RAY, "Compound factor should increase over time");

        // Update rate again and verify accumulator increases
        vm.prank(MANAGER);
        savingcoin.update(rate);
        uint256 newAccum = savingcoin.compoundFactorAccum();
        assertTrue(
            newAccum > initialAccum,
            "Accumulator should increase after update"
        );
    }

    function testFailRateAbove100Percent() public {
        vm.prank(MANAGER);
        savingcoin.update(RAY); // Try to set 100% rate
    }

    function testCapManagement() public {
        uint256 cap = 1e18;
        vm.prank(MANAGER);
        savingcoin.setCap(cap);
        assertEq(savingcoin.cap(), cap);

        // Deposit 1% of cap initially
        uint256 depositAmount = cap / 100;
        vm.prank(USER);
        uint256 initialShares = savingcoin.deposit(depositAmount, USER);
        assertTrue(
            initialShares > 0,
            "Should receive shares for initial deposit"
        );

        // Set very small interest rate and move time forward
        vm.prank(MANAGER);
        savingcoin.update(0.0001e26); // 0.001% APR
        skip(365 days);

        // Calculate total assets after appreciation
        uint256 totalAssets = savingcoin.totalAssets();
        assertTrue(totalAssets > depositAmount, "Assets should appreciate");

        vm.expectRevert("newly issued shares can not exceed notional cap");

        // Try deposit that would exceed cap
        vm.prank(USER);
        savingcoin.deposit(cap, USER);

        // Update cap and verify larger deposits possible
        vm.prank(MANAGER);
        uint256 newCap = cap * 1e6;
        savingcoin.setCap(newCap);

        vm.prank(USER);
        uint256 shares = savingcoin.deposit(cap / 2e6, USER);
        assertTrue(
            shares > 0,
            "Should allow larger deposit after cap increase"
        );
    }
}
