// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract TestnetERC20 is ERC20, AccessControl {
    uint8 immutable _decimals;
    uint256 public constant ONE_ETH = 10 ** 18;
    bytes32 public constant ADMINS = keccak256("ADMINS");

    address public treasurySwap;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 decimals_
    ) ERC20(_name, _symbol) {
        _decimals = decimals_;

        // Assign the deployer as the initial admin
        _grantRole(ADMINS, msg.sender);
    }

    /// @notice Set the TreasurySwap contract address (can be set only once)
    /// @param _treasurySwap The address of the TreasurySwap contract
    function setTreasurySwap(address _treasurySwap) external onlyRole(ADMINS) {
        require(_treasurySwap != address(0), "Invalid address");
        treasurySwap = _treasurySwap;
    }

    /// @notice Only TreasurySwap can mint tokens
    /// @param to The recipient address
    /// @param amount The amount to mint
    function mint(address to, uint256 amount) external {
        require(msg.sender == treasurySwap, "Only TreasurySwap can mint");
        _mint(to, amount);
    }

    /// @notice Only TreasurySwap can burn tokens
    /// @param from The address whose tokens will be burned
    /// @param amount The amount to burn
    function burn(address from, uint256 amount) external {
        require(msg.sender == treasurySwap, "Only TreasurySwap can burn");
        _burn(from, amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    // ------------------ Treasury Management Functions ------------------

    /// @notice Withdraw ERC20 tokens from the contract
    /// @param amount The amount of tokens to withdraw
    function adminWithdraw(uint256 amount) public onlyRole(ADMINS) {
        require(amount > 0, "Invalid amount");
        _transfer(address(this), msg.sender, amount);
    }

    /// @notice Withdraw ETH from the contract
    /// @param amount The amount of ETH to withdraw
    function adminWithdrawETH(uint256 amount) public onlyRole(ADMINS) {
        require(amount > 0, "Invalid amount");
        (bool success, ) = msg.sender.call{value: amount}(new bytes(0));
        require(success, "ETH Admin Withdraw failed");
    }
    

    /// @notice Get the balance of ERC20 tokens in the contract
    function treasuryERCBalance() public view returns (uint256) {
        return balanceOf(address(this));
    }

    /// @notice Get the balance of a specific address
    /// @param addr The address to check balance for
    function addressBalance(address addr) public view returns (uint256) {
        return balanceOf(addr);
    }

    /// @notice Get the current TreasurySwap contract address
    /// @return The address of the TreasurySwap contract
    function getTreasurySwap() public view returns (address) {
        return treasurySwap;
    }
}
