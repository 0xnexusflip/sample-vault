// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title ERC20 Sample Vault
/// @notice A simple pausable Vault integration with an ERC20 token whitelist and access control
/// @dev Inherits OpenZeppelins' Ownable contract
contract Vault is Ownable {
    /// @notice ERC20 addresses for which token is whitelisted (true -» whitelisted, false -» !whitelisted)
    mapping(address => bool) private whitelistedTokens;

    /// @dev User address -» ERC20 address -» Amount deposited
    mapping(address => mapping(address => uint256)) public deposits;

    /// @notice Flag to pause contract if owner
    bool public paused;

    /// @notice Emitted when deposit is executed
    /// @param user Address of depositor
    /// @param token ERC20 address for whitelisted token deposited by user
    /// @param amount Amount deposited
    event Deposit(address indexed user, address indexed token, uint256 amount);

    /// @notice Emitted when withdraw is executed
    /// @param user Address of withdrawer
    /// @param token ERC20 address for whitelisted token deposited by user
    /// @param amount Amount withdrawn
    event Withdraw(address indexed user, address indexed token, uint256 amount);

    /// @notice Checks if contract is paused
    /// @dev If paused, reverts
    modifier whenNotPaused() {
        require(!paused, "Vault is paused");
        _;
    }

    /// @notice Checks if ERC20 token address is whitelisted
    /// @param _token ERC20 token address to check
    /// @dev If not whitelisted, reverts
    modifier onlyWhitelisted(address _token) {
        require(whitelistedTokens[_token], "Token not whitelisted");
        _;
    }

    /// @notice Checks if function caller is not address(0)
    /// @param _address Address of function caller
    /// @dev If address(0), reverts
    modifier notZeroAddress(address _address) {
        require(_address != address(0), "Zero address");
        _;
    }

    /// @notice Contract constructor (inherits Ownable properties for access control)
    /// @notice Contract deployer address gets Admin access
    /// @dev unpaused by default
    constructor() Ownable(msg.sender) {
        paused = false;
    }

    /// @notice Pauses contract (disables usage)
    /// @notice Can only be called by Admin
    function pause() public onlyOwner {
        paused = true;
    }

    /// @notice Unpauses contract (resumes usage)
    /// @notice Can only be called by Admin
    function unpause() public onlyOwner {
        paused = false;
    }

    /// @notice Whitelists ERC20 address, enabling deposits
    /// @notice Can only be called by Admin
    /// @param _token ERC20 token address to whitelist
    function whitelistToken(address _token) public onlyOwner {
        whitelistedTokens[_token] = true;
    }

    /// @notice Address that calls function deposits given amount of respective ERC20 token
    /// @param _token ERC20 address of token to deposit
    /// @param _amount Amount of _token to deposit
    /// @dev Emits Deposit event
    /// @dev Requires contract to be unpaused and ERC20 token address to be whitelisted
    /// @dev If user balance lt amount of token to deposit, reverts
    /// @dev If amount to deposit == 0, reverts
    /// @dev If msg.sender == address(0), reverts
    function deposit(
        address _token,
        uint256 _amount
    ) public whenNotPaused onlyWhitelisted(_token) notZeroAddress(msg.sender) {
        require(_amount > 0, "Cannot deposit 0");
        require(
            IERC20(_token).transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );

        deposits[msg.sender][_token] += _amount;

        emit Deposit(msg.sender, _token, _amount);
    }

    /// @notice Address that calls function withdraws given amount of respective ERC20 token
    /// @param _token ERC20 address of token to withdraw
    /// @param _amount Amount of _token to withdraw
    /// @dev Emits Withdraw event
    /// @dev Requires contract to be unpaused and ERC20 token address to be whitelisted
    /// @dev If amount of token deposited lt amount of token withdraw, reverts
    /// @dev If amount to withdraw == 0, reverts
    /// @dev If msg.sender == address(0), reverts
    function withdraw(
        address _token,
        uint256 _amount
    ) public whenNotPaused onlyWhitelisted(_token) notZeroAddress(msg.sender) {
        require(_amount > 0, "Cannot withdraw 0");

        require(
            deposits[msg.sender][_token] >= _amount,
            "Insufficient balance"
        );
        deposits[msg.sender][_token] -= _amount;

        require(
            IERC20(_token).transfer(msg.sender, _amount),
            "Transfer failed"
        );

        emit Withdraw(msg.sender, _token, _amount);
    }
}
