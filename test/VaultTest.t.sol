// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Vault.sol";
import "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract VaultTest is Test {
    /// PUBLIC VARIABLES
    Vault public vault;
    ERC20Mock public token;

    uint256 public depositAmount;
    uint256 public mintAmount;

    // EVENTS

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdraw(address indexed user, address indexed token, uint256 amount);

    /// TESTING SUITE SET-UP

    function setUp() public {
        //Init vault and mock ERC20
        vault = new Vault();
        token = new ERC20Mock();

        //Amount to mint for test
        mintAmount = 1000 ether;

        // Mint tokens
        token.mint(address(this), mintAmount);

        // Approve tokens for Vault usage
        token.approve(address(vault), type(uint256).max);
        
        // Mock amount for testing
        depositAmount = 100 ether;
    }

    /// END-TO-END TESTING

    /// @notice End-to-end test for user deposit and withdraw
    function testDepositWithdraw() public {
        //Whitelist ERC20 token
        vault.whitelistToken(address(token));

        //Deposit token
        vault.deposit(address(token), depositAmount);

        //Assert deposit amount
        assertEq(token.balanceOf(address(vault)), depositAmount);
        assertEq(vault.deposits(address(this), address(token)), depositAmount);

        //Withdraw token
        vault.withdraw(address(token), depositAmount);

        //Assert withdrawn amount
        assertEq(token.balanceOf(address(this)), mintAmount);
    }

    /// @notice End-to-end test for pausing and unpausing contract
    function testPauseAndUnpause() public {
        //Whitelist ERC20 token
        vault.whitelistToken(address(token));
        
        //Pause contract
        vault.pause();

        //Expect revert
        vm.expectRevert("Vault is paused");
        vault.deposit(address(token), depositAmount);

        //Unpause contract
        vault.unpause();
        
        //Expect pass
        vault.deposit(address(token), depositAmount);
    }

    /// @notice End-to-end test for multiple user deposit and withdraws
    function testMultiplDepositWithdraws() public {
        //Setup additional user accounts and ERC20 mock token
        address user2 = address(0x2);
        vm.deal(user2, 1 ether);
        ERC20Mock token2 = new ERC20Mock();
        
        //Whitelist ERC20 tokens
        vault.whitelistToken(address(token));
        vault.whitelistToken(address(token2));

        token2.mint(user2, 500 ether);
        vm.prank(user2);
        token2.approve(address(vault), type(uint256).max);

        //Alice deposit
        uint256 aliceDeposit = 100 ether;
        vault.deposit(address(token), aliceDeposit);

        //Bob deposit
        vm.prank(user2);
        uint256 bobDeposit = 200 ether;
        vault.deposit(address(token2), bobDeposit);

        //Assert balances for Alice and Bob
        assertEq(vault.deposits(address(this), address(token)), aliceDeposit);
        assertEq(vault.deposits(user2, address(token2)), bobDeposit);

        //Alice and Bob withdraw
        vault.withdraw(address(token), aliceDeposit);
        vm.prank(user2);
        vault.withdraw(address(token2), bobDeposit);

        //Assert balances for Alice and Bob
        assertEq(token.balanceOf(address(this)), 1000 ether);
        assertEq(token2.balanceOf(user2), 500 ether);
    }

    /// FUZZING

    ///@notice Fuzz test for checking revert when withdraw amount gt user deposit
    function testFuzzWithdrawGtDeposit(uint256 amount) public {
        //Whitelist ERC20 token
        vault.whitelistToken(address(token));

        //Expect revert
        if (amount > 100 ether) {
            vm.expectRevert("Insufficient balance");
            vault.withdraw(address(token), amount);
        }
    }

    /// EVENT TESTING

    /// @notice Unit test for checking deposit event
    function testDepositEmit() public {
        //Whitelist ERC20
        vault.whitelistToken(address(token));

        //Expect event
        vm.expectEmit(true, true, false, true);
        emit Deposit(address(this), address(token), depositAmount);

        //Withdraw amount
        vault.deposit(address(token), depositAmount);
    }

    /// @notice Unit test for checking withdraw event
    function testWithdrawEmit() public {
        //Whitelist ERC20
        vault.whitelistToken(address(token));

        //Deposit amount
        vault.deposit(address(token), depositAmount);

        //Expect event
        vm.expectEmit(true, true, false, true);
        emit Withdraw(address(this), address(token), depositAmount);

        //Withdraw amount
        vault.withdraw(address(token), depositAmount);
    }

    /// REVERT TESTING

    ///@notice Revert test for pausing contract without access control
    function testFailUnauthorizedPause() public {
        //Set address to non-authorized
        vm.prank(address(0x123));

        //Expect access control revert when attempting pause
        vault.pause();
    }

    ///@notice Revert test for unpausing contract without access control
    function testFailUnauthorizedUnpause() public {
        //Set address to non-authorized
        vm.prank(address(0x123));

        //Expect access control revert when attempting unpause
        vault.unpause();
    }

    ///@notice Revert test for whitelisting ERC20 token address without access control
    function testFailUnauthorizedWhitelistToken() public {
        //Set address to non-authorized
        vm.prank(address(0x123));

        //Expect access control revert when attempting token whitelisting
        vault.whitelistToken(address(0x456));
    }

    /// @notice Revert test for depositing when Vault is paused
    function testDepositPaused() public {
        //Whitelist ERC20 token
        vault.whitelistToken(address(token));

        //Pause contract
        vault.pause();
        
        //Expect pause revert
        vm.expectRevert("Vault is paused");
        vault.deposit(address(token), 50 ether);

    }

    /// @notice Revert test for withdrawing when Vault is paused
    function testWithdrawPaused() public {
        //Whitelist ERC20 token
        vault.whitelistToken(address(token));

        //Deposit amount
        vault.deposit(address(token), 50 ether);

        //Pause contract
        vault.pause();
        
        //Expect pause revert
        vm.expectRevert("Vault is paused");
        vault.withdraw(address(token), 50 ether);

    }

    /// @notice Revert test for checking deposit with non-whitelisted token
    function testDepositNonWhitelisted() public {
        //Init non-whitelisted ERC20 token
        ERC20Mock nonWhitelistedToken = new ERC20Mock();

        //Mint token
        nonWhitelistedToken.mint(address(this), depositAmount);

        //Expect whitelist revert
        vm.expectRevert("Token not whitelisted");
        vault.deposit(address(nonWhitelistedToken), depositAmount);

    }
}