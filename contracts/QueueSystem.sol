// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title Queue Management with VIP Upgrade

contract QueueSystem {
    // Struct to hold user information
    struct User {
        uint256 queueNumber; // User's current queue number
        bool isVIP; // Whether the user is a VIP
        uint256 vipPaymentTime; // Time when the user paid for VIP upgrade
    }

    // Mapping from user's address to their details
    mapping(address => User) public users;

    // List of addresses representing the queue order
    address[] public queue;

    // Owner's address to collect VIP payments
    address public owner;

    // VIP upgrade cost in Wei
    uint256 public vipCost = 0.0001 ether;

    // Events
    event JoinedQueue(address indexed user, uint256 queueNumber);
    event UpgradedToVIP(address indexed user, uint256 newPosition);

 /// @notice Constructor to initialize the owner
    constructor(address _owner) {
        require(_owner != address(0), "Invalid owner address"); // Ensure the owner address is valid
        owner = _owner; // Set the owner's address
    }

    /// @notice Function to join the queue
    function joinQueue() external {
        // Ensure the user has not already joined the queue
        require(users[msg.sender].queueNumber == 0, "Already in queue");

        // Assign the user's queue number as the next available position
        uint256 newQueueNumber = queue.length + 1;
        users[msg.sender] = User(newQueueNumber, false, 0);
        queue.push(msg.sender); // Add the user to the queue

        emit JoinedQueue(msg.sender, newQueueNumber); // Emit event
    }

     /// @notice Function to upgrade the user to VIP
   function upgradeToVIP() external payable {
    // Ensure the user is in the queue
    require(users[msg.sender].queueNumber != 0, "Not in queue");

    // Ensure the user is not already a VIP
    require(!users[msg.sender].isVIP, "Already a VIP");

    // Ensure the user sends the correct amount for VIP upgrade
    require(msg.value == vipCost, "Incorrect VIP cost");

    // Transfer the VIP payment to the owner
    payable(owner).transfer(msg.value);

    // Upgrade the user to VIP
    users[msg.sender].isVIP = true;

    // Record the VIP payment time
    uint256 paymentTime = block.timestamp;
    users[msg.sender].vipPaymentTime = paymentTime;

    // Reorder the queue based on VIP status and payment time
    address[] memory tempQueue = new address[](queue.length);
    uint256 tempIndex = 0;

    // Add all VIP users first, sorted by payment time
    for (uint256 i = 0; i < queue.length; i++) {
        if (users[queue[i]].isVIP) {
            tempQueue[tempIndex] = queue[i];
            tempIndex++;
        }
    }

    // Sort the VIP users by payment time
    for (uint256 i = 0; i < tempIndex - 1; i++) {
        for (uint256 j = 0; j < tempIndex - i - 1; j++) {
            if (users[tempQueue[j]].vipPaymentTime > users[tempQueue[j + 1]].vipPaymentTime) {
                (tempQueue[j], tempQueue[j + 1]) = (tempQueue[j + 1], tempQueue[j]);
            }
        }
    }

    // Add non-VIP users at the end in their original order
    for (uint256 i = 0; i < queue.length; i++) {
        if (!users[queue[i]].isVIP) {
            tempQueue[tempIndex] = queue[i];
            tempIndex++;
        }
    }

    // Update the main queue with the reordered list
    queue = tempQueue;

    // Update queue numbers for all users
    for (uint256 i = 0; i < queue.length; i++) {
        users[queue[i]].queueNumber = i + 1; // Update queue number
    }

    emit UpgradedToVIP(msg.sender, users[msg.sender].queueNumber); // Emit event with the new position
}


    /// @notice Get the user's current queue number
    /// @param user The address of the user
    /// @return The queue number of the user
    function getQueueNumber(address user) external view returns (uint256) {
        return users[user].queueNumber;
    }

    /// @notice Get the queue size
    /// @return The total number of users in the queue
    function getQueueSize() external view returns (uint256) {
        return queue.length;
    }

    /// @notice Function to get the entire queue (for debugging or admin purposes)
    function getFullQueue() external view returns (address[] memory) {
        return queue;
    }

}
