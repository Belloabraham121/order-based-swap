// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title OrderSwapContract
 * @dev A contract for creating and executing token swap orders
 * This contract allows users to create orders to swap one ERC20 token for another,
 * cancel their own orders, and execute orders created by others.
 */
contract OrderSwapContract is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    /**
     * @dev Struct to represent a swap order
     */
    struct Order {
        uint256 orderId;        // Unique identifier for the order
        address seller;         // Address of the order creator
        address tokenForSale;   // Address of the token being sold
        uint256 amountForSale;  // Amount of tokens being sold
        address tokenWanted;    // Address of the token wanted in exchange
        uint256 amountWanted;   // Amount of tokens wanted in exchange
        bool isActive;          // Whether the order is still active
    }

    // Mapping from order ID to Order struct
    mapping(uint256 => Order) public orders;
    
    // Next available order ID
    uint256 public nextOrderId;
    
    // 2D mapping for user balances: user address => token address => amount
    mapping(address => mapping(address => uint256)) public userBalances;

    // Events
    event OrderCreated(uint256 orderId, address seller, address tokenForSale, uint256 amountForSale, address tokenWanted, uint256 amountWanted);
    event OrderCancelled(uint256 orderId);
    event OrderExecuted(uint256 orderId, address buyer);
    event TokensDeposited(address user, address token, uint256 amount);
    event TokensWithdrawn(address user, address token, uint256 amount);

    /**
     * @dev Contract constructor
     * @param initialOwner The address to be set as the initial owner of the contract
     */
    constructor(address initialOwner) Ownable(initialOwner) {
        nextOrderId = 0;
    }

    /**
     * @dev Creates a new order and deposits the tokens for sale
     * @param tokenForSale Address of the token being sold
     * @param amountForSale Amount of tokens being sold
     * @param tokenWanted Address of the token wanted in exchange
     * @param amountWanted Amount of tokens wanted in exchange
     */
    function createOrderAndDeposit(
        address tokenForSale,
        uint256 amountForSale,
        address tokenWanted,
        uint256 amountWanted
    ) external nonReentrant {
        require(msg.sender != address(0), "Address zero detected");
        require(tokenForSale != tokenWanted, "Cannot swap a token for itself");
        require(tokenForSale != address(0) && tokenWanted != address(0), "Invalid token address");
        require(amountForSale > 0 && amountWanted > 0, "Amounts must be greater than zero");

        // Check if the seller has sufficient balance of tokenForSale
        require(IERC20(tokenForSale).balanceOf(msg.sender) >= amountForSale, "Insufficient balance of token for sale");


        // Transfer tokens from user to contract
        IERC20(tokenForSale).safeTransferFrom(msg.sender, address(this), amountForSale);

        uint256 _orderId = nextOrderId + 1;
        Order storage newOrder = orders[_orderId];

        newOrder.orderId = _orderId;
        newOrder.seller = msg.sender;
        newOrder.tokenForSale = tokenForSale;
        newOrder.amountForSale = amountForSale;
        newOrder.tokenWanted = tokenWanted;
        newOrder.amountWanted = amountWanted;
        newOrder.isActive = true;

        nextOrderId += 1;

        emit OrderCreated(_orderId, msg.sender, tokenForSale, amountForSale, tokenWanted, amountWanted);
    }

    /**
     * @dev Cancels an existing order
     * @param _orderId The ID of the order to be cancelled
     */
    function cancelOrder(uint256 _orderId) external {
        require(_orderId > 0 && _orderId < nextOrderId, "Invalid order ID");
        Order storage order = orders[_orderId];
        require(order.isActive, "Order is not active");
        require(order.seller == msg.sender, "Not the order creator");

        order.isActive = false;
        userBalances[msg.sender][order.tokenForSale] += order.amountForSale;

        emit OrderCancelled(_orderId);
    }

    /**
     * @dev Executes an existing order
     * @param _orderId The ID of the order to be executed
     */
    function executeOrder(uint256 _orderId) external nonReentrant {
        require(_orderId > 0 && _orderId < nextOrderId, "Invalid order ID");
        Order storage order = orders[_orderId];
        require(order.isActive, "Order is not active");
        require(msg.sender != order.seller, "Seller cannot execute their own order");

        // Check if buyer has sufficient balance of tokenWanted
        require(IERC20(order.tokenWanted).balanceOf(msg.sender) >= order.amountWanted, "Insufficient balance to execute order");


        order.isActive = false;

        // Transfer tokenWanted from buyer to seller
        IERC20(order.tokenWanted).safeTransferFrom(msg.sender, order.seller, order.amountWanted);

        // Transfer tokenForSale from contract to buyer
        IERC20(order.tokenForSale).safeTransfer(msg.sender, order.amountForSale);

        emit OrderExecuted(_orderId, msg.sender);
    }


    /**
     * @dev Retrieves the details of a specific order
     * @param _orderId The ID of the order to retrieve
     * @return Order struct containing the order details
     */
    function getOrderDetails(uint256 _orderId) external view returns (Order memory) {
        require(_orderId > 0 && _orderId < nextOrderId, "Invalid order ID");
        return orders[_orderId];
    }

    /**
     * @dev Retrieves the balance of a specific token for a user
     * @param user Address of the user
     * @param token Address of the token
     * @return uint256 Balance of the token for the user
     */
    function getUserBalance(address user, address token) external view returns (uint256) {
        return userBalances[user][token];
    }

    /**
     * @dev Allows the contract owner to withdraw all tokens of a specific type in case of emergency
     * @param token Address of the token to withdraw
     */
    function emergencyWithdraw(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(owner(), balance);
    }
}