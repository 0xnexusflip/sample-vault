// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Vault.sol";
import "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract VaultTest is Test {
    /// PUBLIC VARIABLES
    Vault public vault;
    ERC20Mock public token;
    Ownable public ownable;

    uint256 public depositAmount;
    uint256 public mintAmount;

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
        vault.whitelistToken(address(token));

        // Mock amount for testing
        depositAmount = 100 ether;
    }

    /// END-TO-END TESTING

    /// @notice End-to-end test for user deposit and withdraw
    function testDepositWithdraw() public {
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
    function testMultipleDepositWithdraws() public {
        //Setup additional user accounts and ERC20 mock token
        address alice = address(0x2);
        address bob = address(0x3);
        ERC20Mock newToken = new ERC20Mock();

        //Whitelist ERC20 newToken
        vault.whitelistToken(address(newToken));

        //Mint token for Alice
        token.mint(alice, 500 ether);

        //Mint newToken for Bob
        newToken.mint(bob, 500 ether);

        //Approve newToken for Alice and Bob
        vm.prank(alice);
        token.approve(address(vault), type(uint256).max);

        vm.prank(bob);
        newToken.approve(address(vault), type(uint256).max);

        //Alice deposit
        vm.prank(alice);
        uint256 aliceDeposit = 100 ether;
        vault.deposit(address(token), aliceDeposit);

        //Bob deposit
        vm.prank(bob);
        uint256 bobDeposit = 200 ether;
        vault.deposit(address(newToken), bobDeposit);

        //Assert balances for Alice and Bob
        assertEq(vault.deposits(alice, address(token)), aliceDeposit);
        assertEq(vault.deposits(bob, address(newToken)), bobDeposit);

        //Alice and Bob withdraw
        vm.prank(alice);
        vault.withdraw(address(token), aliceDeposit);

        vm.prank(bob);
        vault.withdraw(address(newToken), bobDeposit);

        //Assert balances for Alice and Bob
        assertEq(token.balanceOf(alice), 500 ether);
        assertEq(newToken.balanceOf(bob), 500 ether);
    }

    /// FUZZING

    ///@notice Fuzz test for end-to-end deposit and withdraw
    function testFuzzDepositWithdraw(uint256 amount) public {
        vm.assume(amount > 0 && amount < 1e77);
        //Prank as Alice
        address alice = address(0x2);
        vm.startPrank(alice);

        //Mint token for Alice
        token.mint(alice, amount);

        //Approve Vault deposit
        token.approve(address(vault), amount);

        //Deposit token
        vault.deposit(address(token), amount);

        //Assert deposit amount
        assertEq(token.balanceOf(address(vault)), amount);
        assertEq(vault.deposits(alice, address(token)), amount);

        //Withdraw token
        vault.withdraw(address(token), amount);

        //Assert withdrawn amount
        assertEq(token.balanceOf(alice), amount);

        vm.stopPrank();
    }

    ///@notice Fuzz test for checking revert when withdraw amount gt user deposit
    function testFuzzWithdrawGtDeposit(uint256 amount) public {
        //Expect revert
        if (amount > 100 ether) {
            vm.expectRevert("Insufficient balance");
            vault.withdraw(address(token), amount);
        }
    }

    /// REVERT TESTING

    /// @notice Revert test for depositing when Vault is paused
    function testDepositPaused() public {
        //Pause contract
        vault.pause();

        //Expect pause revert
        vm.expectRevert("Vault is paused");
        vault.deposit(address(token), 50 ether);
    }

    /// @notice Revert test for withdrawing when Vault is paused
    function testWithdrawPaused() public {
        //Deposit amount
        vault.deposit(address(token), 50 ether);

        //Pause contract
        vault.pause();

        //Expect pause revert
        vm.expectRevert("Vault is paused");
        vault.withdraw(address(token), 50 ether);
    }

    /// @notice Revert test for depositing 0 token
    function testZeroDeposit() public {
        //Expect 0 token amount revert
        vm.expectRevert("Cannot deposit 0");
        vault.deposit(address(token), 0);
    }

    /// @notice Revert test for withdrawing 0 token
    function testZeroWithdraw() public {
        //Expect 0 token amount revert
        vm.expectRevert("Cannot withdraw 0");
        vault.withdraw(address(token), 0);
    }

    /// @notice Revert test for deposit from address(0)
    function testNotAddressZeroDeposit() public {
        //Expect address(0) revert
        vm.expectRevert("Zero address");
        vm.prank(address(0));
        vault.deposit(address(token), depositAmount);
    }

    /// @notice Revert test for withdraw from address(0)
    function testNotAddressZeroWithdraw() public {
        //Expect address(0) revert
        vm.expectRevert("Zero address");
        vm.prank(address(0));
        vault.withdraw(address(token), depositAmount);
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

    ///@notice Revert test for pausing contract without access control
    function testFailAccessPause() public {
        //Set address to non-authorized
        vm.prank(address(0x123));
        
        //Expect access control revert when attempting pause
        vault.pause();
    }

    ///@notice Revert test for unpausing contract without access control
    function testFailAccessUnpause() public {
        //Set address to non-authorized
        vm.prank(address(0x123));

        //Expect access control revert when attempting unpause
        vault.unpause();
    }

    ///@notice Revert test for whitelisting ERC20 token address without access control
    function testFailAccessWhitelist() public {
        //Set address to non-authorized
        vm.prank(address(0x123));

        //Expect access control revert when attempting token whitelisting
        vault.whitelistToken(address(0x456));
    }
}
