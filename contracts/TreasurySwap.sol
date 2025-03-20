// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import {TestnetERC20} from "./TestnetERC20.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract TreasurySwap is Ownable {
    TestnetERC20 private  token;
    address public wTON;
    uint256 public tokenValue;
    uint256 public upperBound;
    uint256 public lowerBound;
    uint8 _decimals;

    constructor(
        address _token,
        address _wTON,
        uint256 _tokenValue,
        uint8 _setDecimals,
        uint256 _upperBound,
        uint256 _lowerBound
    ) Ownable(msg.sender) {
        token = TestnetERC20(payable(_token));
        wTON = _wTON;
        tokenValue = _tokenValue;
        _decimals = _setDecimals;
        upperBound = _upperBound;
        lowerBound = _lowerBound;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 wTONamt) public returns (uint256) {
        require(wTONamt > 0, "TreasurySwap: You need to send some wTON");
        require(
            IERC20(wTON).balanceOf(msg.sender) >= wTONamt,
            "TreasurySwap: Not enough wTON balance"
        );
        uint256 amount = (wTONamt * tokenValue) / (10 ** 9);
        require(amount > lowerBound, "TreasurySwap: Requested balance too low");
        require(
            amount < upperBound,
            "TreasurySwap: Requested balance too high"
        );

        bool success = IERC20(wTON).transferFrom(
            msg.sender,
            address(this),
            wTONamt
        );
        require(
            success,
            "TreasurySwap: Can't take wTON from user. Likely insufficient balance"
        );

        uint256 faucetBalance = token.balanceOf(address(this));
        require(
            amount <= faucetBalance,
            "TreasurySwap: Not enough tokens in the treasury"
        );

        token.mint(to, amount); // Use TestnetERC20's mint function

        return amount;
    }

    function burn(address to, uint256 amount) public returns (uint256) {
        require(
            amount > 0,
            "TreasurySwap: You need to sell at least some tokens"
        );

        require(
            amount < upperBound,
            "TreasurySwap: You are requesting to sell too much tokens"
        );

        uint256 availableBalance = token.balanceOf(msg.sender);
        require(
            amount <= availableBalance,
            "TreasurySwap: Requested burn amount greater than current balance"
        );

        token.burn(to, amount); // Use TestnetERC20's mint function

        uint256 refundAmount = (amount * 10 ** 9) / tokenValue;

        IERC20(wTON).transfer(to, refundAmount);

        return refundAmount;
    }

    function getTokenValue(uint256 wTONamt) public view returns (uint256) {
        require(wTONamt > 0, "TreasurySwap: You need to send some wTON");

        uint256 amount = (wTONamt * tokenValue) / (10 ** 9);

        return amount;
    }

    function getWtonValue(uint256 tokenAmount) public view returns (uint256) {
        require(
            tokenAmount > 0,
            "TreasurySwap: You need to send some token amount"
        );

        uint256 refundAmount = (tokenAmount * 10 ** 9) / tokenValue;

        return refundAmount;
    }

    receive() external payable {}

    fallback() external payable {}
}
