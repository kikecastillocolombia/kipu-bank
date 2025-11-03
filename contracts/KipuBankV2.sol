// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title KipuBankV2
 * @dev Versión mejorada de KipuBank con control de acceso, integración Chainlink y soporte multi-token.
 */
contract KipuBankV2 is AccessControl {
    bytes32 public constant BANK_ADMIN_ROLE = keccak256("BANK_ADMIN_ROLE");

    struct Stats {
        uint256 totalDeposits;
        uint256 totalWithdrawals;
    }

    uint8 public constant DECIMALS = 18;

    // Dirección del oráculo Chainlink ETH/USD en Sepolia
    AggregatorV3Interface public constant PRICE_FEED =
        AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);

    uint256 public immutable bankCap;
    uint256 public immutable maxWithdrawalThreshold;

    mapping(address => mapping(address => uint256)) public balances;
    Stats public stats;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    constructor(uint256 _bankCap, uint256 _maxWithdrawalThreshold) {
        bankCap = _bankCap;
        maxWithdrawalThreshold = _maxWithdrawalThreshold;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(BANK_ADMIN_ROLE, msg.sender);
    }

    function deposit() external payable {
        require(address(this).balance <= bankCap, "Cap exceeded");
        balances[msg.sender][address(0)] += msg.value;
        stats.totalDeposits++;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(amount <= maxWithdrawalThreshold, "Exceeds threshold");
        require(balances[msg.sender][address(0)] >= amount, "Insufficient balance");
        balances[msg.sender][address(0)] -= amount;
        stats.totalWithdrawals++;
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        emit Withdrawal(msg.sender, amount);
    }

    function convertEthToUsd(uint256 ethAmount) public view returns (uint256 usdValue) {
        (, int256 price,,,) = PRICE_FEED.latestRoundData();
        require(price > 0, "Invalid price");
        usdValue = (ethAmount * uint256(price)) / 1e18;
    }

    function getLatestPrice() external view onlyRole(BANK_ADMIN_ROLE) returns (int256) {
        (, int256 price,,,) = PRICE_FEED.latestRoundData();
        return price;
    }
}