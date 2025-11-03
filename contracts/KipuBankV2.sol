// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title KipuBankV2
 * @author Solidity Developer
 * @notice Vault-like contract for native ETH deposits with role-based access control, Chainlink price feed,
 *         nested balances (multi-asset ready), constants and conversion utilities.
 * @dev Uses Checks-Effects-Interactions, custom errors and OpenZeppelin AccessControl.
 *
 * NOTE: To verify on Etherscan, use a flattened file (Remix -> File -> Flatten) before pasting into Etherscan verify UI.
 */

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// -----------------------------------------------------------------------
/// --------------------------- Custom Errors ------------------------------
/// -----------------------------------------------------------------------
error NotOwner();
error DepositExceedsBankCap(uint256 requested, uint256 cap);
error WithdrawalExceedsThreshold(uint256 requested, uint256 threshold);
error InsufficientBalance(uint256 available, uint256 requested);
error InvalidPriceFeed();
error TransferFailed(address to, uint256 amount);

/// -----------------------------------------------------------------------
/// ---------------------------- KipuBankV2 --------------------------------
/// -----------------------------------------------------------------------
contract KipuBankV2 is AccessControl {
    // -----------------------------
    // Roles
    // -----------------------------
    bytes32 public constant BANK_ADMIN_ROLE = keccak256("BANK_ADMIN_ROLE");

    // -----------------------------
    // Types
    // -----------------------------
    /// @notice Type to identify the asset slot. address(0) == native ETH.
    enum AssetType { NATIVE, ERC20 }

    /// @notice Struct for global statistics
    struct Stats {
        uint256 totalDeposits;
        uint256 totalWithdrawals;
        uint256 totalValueLockedWei;
    }

    // -----------------------------
    // Constants / Immutables
    // -----------------------------
    /// @notice Number of decimals generally used for ETH (wei precision).
    uint8 public constant ETH_DECIMALS = 18;

    /// @notice Chainlink ETH / USD price feed (Sepolia). Replace with network-specific address if needed.
    AggregatorV3Interface public constant PRICE_FEED =
        AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);

    /// @notice Global maximum the bank can hold (wei)
    uint256 public immutable bankCapWei;

    /// @notice Max withdrawal per transaction (wei)
    uint256 public immutable maxWithdrawalThresholdWei;

    // -----------------------------
    // Storage
    // -----------------------------
    /// @notice balances[user][assetAddress] where assetAddress == address(0) means native ETH
    mapping(address => mapping(address => uint256)) public balances;

    /// @notice per-user deposit count (example of nested mapping usage if needed later)
    mapping(address => uint256) public userDepositCount;

    /// @notice Global stats
    Stats public stats;

    /// @notice Owner (deployer) convenience view
    address public immutable deployer;

    // -----------------------------
    // Events
    // -----------------------------
    event Deposit(address indexed user, address indexed asset, uint256 amountWei, uint256 newBalanceWei);
    event Withdrawal(address indexed user, address indexed asset, uint256 amountWei, uint256 newBalanceWei);
    event AdminWithdraw(address indexed admin, address indexed recipient, uint256 amountWei);

    // -----------------------------
    // Constructor
    // -----------------------------
    /**
     * @param _bankCapWei Maximum wei the contract may hold.
     * @param _maxWithdrawalThresholdWei Maximum wei per withdrawal.
     */
    constructor(uint256 _bankCapWei, uint256 _maxWithdrawalThresholdWei) {
        bankCapWei = _bankCapWei;
        maxWithdrawalThresholdWei = _maxWithdrawalThresholdWei;
        deployer = msg.sender;

        // Grant roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(BANK_ADMIN_ROLE, msg.sender);
    }

    // -----------------------------
    // Modifiers
    // -----------------------------
    modifier onlyAdmin() {
        if (!hasRole(BANK_ADMIN_ROLE, msg.sender)) revert NotOwner();
        _;
    }

    // -----------------------------
    // Public / External Functions
    // -----------------------------

    /**
     * @notice Deposit native ETH to caller's vault.
     * @dev Checks the global bank cap before accepting deposit. Uses Checks-Effects-Interactions.
     */
    function deposit() external payable {
        uint256 incoming = msg.value;
        // 1) Checks
        uint256 newBalanceContract = address(this).balance;
        if (newBalanceContract > bankCapWei) revert DepositExceedsBankCap(newBalanceContract, bankCapWei);

        // 2) Effects
        balances[msg.sender][address(0)] += incoming; // nested mapping: user -> assetAddress (0 = ETH)
        userDepositCount[msg.sender] += 1;
        unchecked { stats.totalDeposits += 1; stats.totalValueLockedWei += incoming; }

        // 3) Interactions (none needed — funds are already on contract)
        emit Deposit(msg.sender, address(0), incoming, balances[msg.sender][address(0)]);
    }

    /**
     * @notice Withdraw native ETH from caller's vault.
     * @param amountWei Amount in wei to withdraw.
     * @dev Follows Checks-Effects-Interactions pattern and enforces per-tx threshold.
     */
    function withdraw(uint256 amountWei) external {
        // 1) Checks
        if (amountWei > maxWithdrawalThresholdWei) revert WithdrawalExceedsThreshold(amountWei, maxWithdrawalThresholdWei);
        uint256 userBal = balances[msg.sender][address(0)];
        if (userBal < amountWei) revert InsufficientBalance(userBal, amountWei);

        // 2) Effects
        balances[msg.sender][address(0)] = userBal - amountWei;
        unchecked { stats.totalWithdrawals += 1; stats.totalValueLockedWei -= amountWei; }

        // 3) Interactions
        (bool ok, ) = payable(msg.sender).call{value: amountWei}("");
        if (!ok) revert TransferFailed(msg.sender, amountWei);

        emit Withdrawal(msg.sender, address(0), amountWei, balances[msg.sender][address(0)]);
    }

    /**
     * @notice Admin emergency withdraw to a safe address (only admin).
     * @dev This function is gated by BANK_ADMIN_ROLE, used for emergency recovery only.
     * @param recipient Address to receive ETH.
     * @param amountWei Amount in wei to send.
     */
    function adminWithdraw(address payable recipient, uint256 amountWei) external onlyAdmin {
        require(recipient != address(0), "zero recipient");
        uint256 contractBal = address(this).balance;
        require(amountWei <= contractBal, "not enough contract balance");

        unchecked { stats.totalValueLockedWei -= amountWei; }
        (bool ok, ) = recipient.call{value: amountWei}("");
        if (!ok) revert TransferFailed(recipient, amountWei);

        emit AdminWithdraw(msg.sender, recipient, amountWei);
    }

    // -----------------------------
    // View / Utility Functions
    // -----------------------------

    /**
     * @notice Get user's balance for a given asset address.
     * @param user Address of the user.
     * @param asset Address of the asset; address(0) == native ETH.
     * @return Balance in wei (for native) or token's smallest unit for ERC20s.
     */
    function getBalance(address user, address asset) external view returns (uint256) {
        return balances[user][asset];
    }

    /**
     * @notice Convert an ETH amount (wei) to USD using Chainlink price feed.
     * @param ethAmountWei Amount in wei to convert.
     * @return usdAmountWith8Decimals USD value scaled to 8 decimals (Chainlink price has 8 decimals on many feeds).
     * @dev Price feeds commonly return price with 8 decimals (e.g., 3000.12345678 USD => 300012345678).
     */
    function convertEthToUsd(uint256 ethAmountWei) public view returns (uint256 usdAmountWith8Decimals) {
        (, int256 price, , , ) = PRICE_FEED.latestRoundData();
        if (price <= 0) revert InvalidPriceFeed();

        // price has 8 decimals, ethAmountWei has 18 decimals.
        // usd = ethAmountWei * price / 1e18
        usdAmountWith8Decimals = (ethAmountWei * uint256(price)) / (10 ** uint256(ETH_DECIMALS));
    }

    /**
     * @notice Convert an USD amount (8 decimals) to an approximate ETH amount (wei).
     * @param usdAmountWith8Decimals USD amount scaled to 8 decimals.
     * @return ethAmountWei Approximate wei for the given USD value.
     */
    function convertUsdToEth(uint256 usdAmountWith8Decimals) external view returns (uint256 ethAmountWei) {
        (, int256 price, , , ) = PRICE_FEED.latestRoundData();
        if (price <= 0) revert InvalidPriceFeed();

        // eth wei = usd * 1e18 / price
        ethAmountWei = (usdAmountWith8Decimals * (10 ** uint256(ETH_DECIMALS))) / uint256(price);
    }

    /**
     * @notice Returns latest ETH/USD price from the feed (8 decimals).
     */
    function getLatestEthUsdPrice() external view returns (int256) {
        (, int256 price, , , ) = PRICE_FEED.latestRoundData();
        return price;
    }

    // -----------------------------
    // Fallback / Receive
    // -----------------------------
    receive() external payable {
        // Accept ETH transfers — treat them as deposits for sender (explicit deposit recommended).
        balances[msg.sender][address(0)] += msg.value;
        unchecked { stats.totalDeposits += 1; stats.totalValueLockedWei += msg.value; }
        emit Deposit(msg.sender, address(0), msg.value, balances[msg.sender][address(0)]);
    }

    fallback() external payable {
        // If calldata present, ignore but accept ETH.
        if (msg.value > 0) {
            balances[msg.sender][address(0)] += msg.value;
            unchecked { stats.totalDeposits += 1; stats.totalValueLockedWei += msg.value; }
            emit Deposit(msg.sender, address(0), msg.value, balances[msg.sender][address(0)]);
        }
    }
}
