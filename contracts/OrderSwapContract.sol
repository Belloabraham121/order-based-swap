// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OrderSwapContract is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    struct Order {
        address seller;
        address tokenForSale;
        uint256 amountForSale;
        address tokenWanted;
        uint256 amountWanted;
        bool isActive;
    }

    mapping(uint256 => Order) public orders;
    uint256 public currentOrderId;
    
    // 2D mapping for user balances: user address => token address => amount
    mapping(address => mapping(address => uint256)) public userBalances;

    event OrderCreated(uint256 orderId, address seller, address tokenForSale, uint256 amountForSale, address tokenWanted, uint256 amountWanted);
    event OrderCancelled(uint256 orderId);
    event OrderExecuted(uint256 orderId, address buyer);
    event TokensDeposited(address user, address token, uint256 amount);
    event TokensWithdrawn(address user, address token, uint256 amount);

    constructor(address initialOwner) Ownable(initialOwner) {}

    function depositTokens(address token, uint256 amount) external {
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than zero");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        userBalances[msg.sender][token] += amount;

        emit TokensDeposited(msg.sender, token, amount);
    }

    function createOrder(
        address tokenForSale,
        uint256 amountForSale,
        address tokenWanted,
        uint256 amountWanted
    ) external {
        require(msg.sender != address(0),"zero address detected");
        require(tokenForSale != address(0) && tokenWanted != address(0), "Invalid token address");
        require(amountForSale > 0 && amountWanted > 0, "Amounts must be greater than zero");
        require(userBalances[msg.sender][tokenForSale] >= amountForSale, "Insufficient balance");

        currentOrderId++;
        orders[currentOrderId] = Order(msg.sender, tokenForSale, amountForSale, tokenWanted, amountWanted, true);

        userBalances[msg.sender][tokenForSale] -= amountForSale;

        emit OrderCreated(currentOrderId, msg.sender, tokenForSale, amountForSale, tokenWanted, amountWanted);
    }

    function cancelOrder(uint256 orderId) external {
        require(msg.sender != address(0),"zero address detected");
        require(orderId > 0 && orderId <= currentOrderId, "Invalid order ID");
        Order storage order = orders[orderId];
        require(order.isActive, "Order is not active");
        require(order.seller == msg.sender, "Not the order creator");

        order.isActive = false;
        userBalances[msg.sender][order.tokenForSale] += order.amountForSale;

        emit OrderCancelled(orderId);
    }

    function executeOrder(uint256 orderId) external nonReentrant {
        require(msg.sender != address(0),"zero address detected");
        require(orderId > 0 && orderId <= currentOrderId, "Invalid order ID");
        Order storage order = orders[orderId];
        require(order.isActive, "Order is not active");
        require(userBalances[msg.sender][order.tokenWanted] >= order.amountWanted, "Insufficient balance to execute order");

        order.isActive = false;
        userBalances[msg.sender][order.tokenWanted] -= order.amountWanted;
        userBalances[msg.sender][order.tokenForSale] += order.amountForSale;
        userBalances[order.seller][order.tokenWanted] += order.amountWanted;

        emit OrderExecuted(orderId, msg.sender);
    }

    function withdrawTokens(address token, uint256 amount) external {
        require(msg.sender != address(0),"zero address detected");
        require(userBalances[msg.sender][token] >= amount, "Insufficient balance");

        userBalances[msg.sender][token] -= amount;
        IERC20(token).safeTransfer(msg.sender, amount);

        emit TokensWithdrawn(msg.sender, token, amount);
    }

    function getOrderDetails(uint256 orderId) external view returns (Order memory) {
        require(orderId > 0 && orderId <= currentOrderId, "Invalid order ID");
        return orders[orderId];
    }

    function getUserBalance(address user, address token) external view returns (uint256) {
        return userBalances[user][token];
    }

    function emergencyWithdraw(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(owner(), balance);
    }
}