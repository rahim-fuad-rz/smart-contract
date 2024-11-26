// Only allowing Ehter bids

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AdvancedAuction is Ownable {

    address public highestBidder;
    uint public highestBid;
    uint public auctionEndTime;
    uint public extensionTime = 5 minutes;  // Extension time for auction when bid is placed near auction end
    bool public auctionEnded;
    
    // Mapping to store refunds for users who were outbid
    mapping(address => uint) public refunds;

    // Events to notify about bids, auction end, and auction extension
    event NewBid(address indexed bidder, uint bidAmount);
    event AuctionEnded(address winner, uint amount);
    event AuctionExtended(uint newEndTime);

    // Modifier to ensure the auction is still open
    modifier auctionOpen() {
        require(block.timestamp < auctionEndTime, "Auction has ended.");
        _;
    }

    // Modifier to ensure the auction has ended
    modifier auctionClosed() {
        require(block.timestamp >= auctionEndTime, "Auction is still ongoing.");
        _;
    }

    // Modifier to allow only the highest bidder to perform certain actions
    modifier onlyHighestBidder() {
        require(msg.sender == highestBidder, "Only the highest bidder can call this function.");
        _;
    }

    // Constructor to initialize the auction duration
    constructor(uint _auctionDuration) {
        auctionEndTime = block.timestamp + _auctionDuration;
        auctionEnded = false;
    }

    // Function to place a bid with Ether
    function placeBid() external payable auctionOpen {
        require(msg.value > highestBid, "Bid must be higher than the current highest bid.");

        // Refund the previous highest bidder
        if (highestBidder != address(0)) {
            refunds[highestBidder] += highestBid;
        }

        // Update the highest bidder and the bid amount
        highestBidder = msg.sender;
        highestBid = msg.value;

        // If the bid is placed close to the end of the auction, extend the time
        if (auctionEndTime - block.timestamp < extensionTime) {
            auctionEndTime += extensionTime;
            emit AuctionExtended(auctionEndTime);
        }

        // Emit a NewBid event
        emit NewBid(msg.sender, msg.value);
    }

    // Function to end the auction and transfer the highest bid to the owner
    function endAuction() external auctionClosed onlyOwner {
        require(!auctionEnded, "Auction has already ended.");
        auctionEnded = true;

        // Transfer the highest bid (Ether) to the owner
        payable(owner()).transfer(highestBid);
        
        // Emit the AuctionEnded event
        emit AuctionEnded(highestBidder, highestBid);
    }

    // Function for the highest bidder to end the auction
    function endAuctionByBidder() external auctionClosed onlyHighestBidder {
        require(!auctionEnded, "Auction has already ended.");
        auctionEnded = true;

        // Transfer the highest bid (Ether) to the owner
        payable(owner()).transfer(highestBid);

        // Emit the AuctionEnded event
        emit AuctionEnded(highestBidder, highestBid);
    }

    // Function to allow outbid users to withdraw their refund
    function withdrawRefund() external {
        uint refundAmount = refunds[msg.sender];
        require(refundAmount > 0, "No funds to withdraw.");

        refunds[msg.sender] = 0;
        payable(msg.sender).transfer(refundAmount);
    }

    // Getter for the current highest bid and bidder
    function getCurrentHighestBid() external view returns (address, uint) {
        return (highestBidder, highestBid);
    }
    
    // Getter for the current auction end time
    function getAuctionEndTime() external view returns (uint) {
        return auctionEndTime;
    }
}
