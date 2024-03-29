// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

//initializes the not owner function
error NotOwner();

contract SubTracker {
    uint256 public subscriptionPrice = 0;
    address public owner;
    uint256 public subscriptionDuration;
    mapping(address => uint256) public lastSubscribed;
    mapping(address => uint256) public subscriptionExpiry;
    mapping(address => bool) public isSubscribed;

    address[] public subscribers;
    address[] public activeSubscribers;
    event SubscriptionPurchased(address indexed user, uint256 expiryTime);
    event SubscriptionExpired(address subscriber);

    //Constructor: Sets initial values upon contract deployment
    constructor(uint256 _initialPrice, uint256 _duration) {
        owner = msg.sender;
        subscriptionPrice = _initialPrice * 1e18; // takes your initial price and converts it to wei,e.g 2 * 1000000000000000000
        subscriptionDuration = _duration;
    }

    //Modifier: ensures only contract deployer can perform certain actions
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // Updates subscription price (only callable by owner)
    function setSubscriptionPrice(uint256 _newPriceinEther) public onlyOwner {
        subscriptionPrice = _newPriceinEther * 1e18;
    }

    //Subscribe function (user triggers this)
    function subscribe() public payable {
        require(
            msg.value <= subscriptionPrice,
            string(
                abi.encodePacked(
                    "Insufficent funds, should be greater than or equal to",
                    subscriptionPrice,
                    "in wei"
                )
            )
        );
        lastSubscribed[msg.sender] = block.timestamp;
        subscriptionExpiry[msg.sender] = block.timestamp + subscriptionDuration;
        subscribers.push(msg.sender);
        updateActiveSubscribers();
    }

    //Checks if a given user has an active subscription
    function isActiveSubscriber(address _user) public view returns (bool) {
        return subscriptionExpiry[_user] >= block.timestamp;
    }

    //Updates the activeSubscribers
    function updateActiveSubscribers() private {
        uint256 newExpiry = block.timestamp + subscriptionDuration;
        if (!isSubscribed[msg.sender]) {
            isSubscribed[msg.sender] = true;
            activeSubscribers.push(msg.sender);
        } else if (block.timestamp > subscriptionExpiry[msg.sender]) {
            subscriptionExpiry[msg.sender] = newExpiry;
        }
        emit SubscriptionPurchased(msg.sender, newExpiry);
    }

    //Returns the subscription expiry time
    function getSubscriptionExpiry(
        address _user
    ) public view returns (uint256) {
        return subscriptionExpiry[_user];
    }

    //Returns: all subscribers both active and inactive
    function getAllSubscribers() public view returns (address[] memory) {
        return subscribers;
    }

    //Returns: all inactive subscribers
    function getInactiveSubscribers() public view returns (address[] memory) {
        uint256 totalSubscribers = subscribers.length;
        uint256 inactiveCount = 0;

        for (uint256 i = 0; i < totalSubscribers; i++) {
            if (subscriptionExpiry[subscribers[i]] < block.timestamp) {
                inactiveCount++;
            }
        }

        address[] memory inactiveSubscribers = new address[](inactiveCount);

        uint256 currentIndex = 0;
        for (uint256 i = 0; i < totalSubscribers; i++) {
            if (subscriptionExpiry[subscribers[i]] < block.timestamp) {
                inactiveSubscribers[currentIndex] = subscribers[i];
                currentIndex++;
            }
        }

        return inactiveSubscribers;
    }

    //Returns: all subscribers in length
    function getTotalSubsribers() public view returns (uint256) {
        return subscribers.length;
    }

    //Returns: a list/ array of active subscribers
    function getTotalActiveSubscribers() public view returns (uint256) {
        return activeSubscribers.length;
    }

    //Returns: a list of in active subscribers
    function getTotalInactiveSubscribers() public view returns (uint256) {
        return subscribers.length - activeSubscribers.length;
    }

    //expires all subscribers with an active subscription
    function expireSubscriptions() public {
        for (uint256 i = 0; i < activeSubscribers.length; i++) {
            if (block.timestamp > subscriptionExpiry[activeSubscribers[i]]) {
                isSubscribed[activeSubscribers[i]] = false;
                subscriptionExpiry[activeSubscribers[i]] = 0;
            }
        }
    }

    //allows the contract owner withdraw the total eth the contract has
    function withDraw() public payable onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        (bool callSuccess, ) = payable(owner).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    //Reciever: ensures that the user can also transfer eth to the contract
    receive() external payable {
        subscribe();
    }

    //Fallback: ensures that if the amount sent is less than or the transaction fails the sent eth can be returned back to the user
    fallback() external payable {
        subscribe();
    }
}
