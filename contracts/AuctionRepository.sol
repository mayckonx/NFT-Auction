// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DeedRepository.sol";

/**
@title Auction Repository
 * This contract allows auctions to be created for non-fungible tokens
 * Moreover, it includes the basic functionalities of an auction house
 */
contract AuctionRepository {
    // Auction struct which holds all the required info
    struct Auction {
        string name;
        uint256 blockDeadline;
        uint256 startPrice;
        string metadata;
        uint256 deedId;
        address deedRepositoryAddress;
        address payable owner;
        bool active;
        bool finalized;
    }

    // Bi struct to hold bidder an amount
    struct Bid {
        address payable from;
        uint256 amount;
    }

    // BidSuccess is fired when a new bid is given to an auction
    event BidSuccess(address _from, uint256 _auctionId);

    // AuctionCreated is fired when an auction is created
    event AuctionCreated(address _owner, uint256 _auctionId);

    // AuctionCanceld is fired when an auction is canceled
    event AuctionCanceled(address _owner, uint256 _auctionId);

    // AuctionFinalized is fired when an auction is finalized
    event AuctionFinalized(address _owner, uint256 _auctionId);

    // Array with all auctions
    Auction[] public auctions;

    // Mapping from auction index to user bids
    mapping(uint256 => Bid[]) public auctionBids;

    // Mapping from owner to a list of owned auctions
    mapping(address => uint256[]) public auctionOwner;

    /*
     * @dev Guarantees msg.sender is owner of the given auction
     * @param _auctionId uint256 ID of the auction to validate its ownership belongs to msg.sender
     */
    modifier isOwner(uint256 _auctionId) {
        require(auctions[_auctionId].owner == msg.sender);
        _;
    }

    /**
     * @dev Guarantees this contract is owner of the given deed/token
     * @param _deedRepositoryAddress address of the deed repository to validate from
     * @param _deedId uint256 ID of the deed which has been registered in the deed repository
     */
    modifier contractIsDeedOwner(
        address payable _deedRepositoryAddress,
        uint256 _deedId
    ) {
        DeedRepository repository = DeedRepository(_deedRepositoryAddress);
        address deedOwner = repository.ownerOf(_deedId);
        require(deedOwner == address(this));
        _;
    }

    /**
     * @dev Gets the lenth of auctions
     * @return uint representing the auction count
     */
    function getCount() public view returns (uint256) {
        return auctions.length;
    }

    /**
     * @dev Gets the bid counts of a given auction
     * @param _auctionId uint ID of the auction
     */
    function getBidsCount(uint256 _auctionId) public view returns (uint256) {
        return auctionBids[_auctionId].length;
    }

    /**
     * @dev Gets an array of owned auctions
     * @param _owner address of the auction owner
     */
    function getAuctionsOf(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory ownedAuctions = auctionOwner[_owner];
        return ownedAuctions;
    }

    /**
     * @dev Gets the current bid amount and user address from the given auction ID
     * @param _auctionId uint of the auction ID
     * @return amount uint256, address of last bidder
     */
    function getCurrentBid(uint256 _auctionId)
        public
        view
        returns (uint256, address)
    {
        uint256 bidsLength = auctionBids[_auctionId].length;
        // if there are bids refund the last bid
        if (bidsLength > 0) {
            Bid memory lastBid = auctionBids[_auctionId][bidsLength - 1];
            return (lastBid.amount, lastBid.from);
        }
        return (uint256(0), address(0));
    }

    /**
     * @dev Gets the total number of auctions owned by an address
     * @param _owner address of the owner
     * @return uint total number of auctions
     */
    function getAuctionsCountOfOwner(address _owner)
        public
        view
        returns (uint256)
    {
        return auctionOwner[_owner].length;
    }

    /**
     * @dev Gets the info of a given auction which are store within a struct
     * @return the auction struct containing all info related to it
     */
    function getAuctionById(uint256 _auctionId)
        public
        view
        returns (Auction memory)
    {
        Auction memory auc = auctions[_auctionId];
        return auc;
    }

    /**
     * @dev Gets the info of a given auction which are store within a struct
     * @return the auction struct containing all info related to it
     */
    function createAuction(Auction memory auction)
        public
        contractIsDeedOwner(
            payable(auction.deedRepositoryAddress),
            auction.deedId
        )
        returns (bool)
    {
        uint256 auctionId = auctions.length;
        auctions.push(auction);
        auctionOwner[msg.sender].push(auctionId);

        emit AuctionCreated(msg.sender, auctionId);
        return true;
    }

    function approveAndTransfer(
        address _from,
        address _to,
        address _deedRepositoryAddress,
        uint256 _deedId
    ) internal returns (bool) {
        DeedRepository remoteContract = DeedRepository(
            payable(_deedRepositoryAddress)
        );
        remoteContract.approve(_to, _deedId);
        remoteContract.transferFrom(_from, _to, _deedId);
        return true;
    }

    /**
     * @dev Cancels an ongoing auction by the owner
     * @dev Deed is transfered back to the auction owner
     * @dev Bidder is refunded with the initial amount
     * @param _auctionId uint ID of the created auction
     */
    function cancelAuction(uint256 _auctionId) public isOwner(_auctionId) {
        Auction memory myAuction = auctions[_auctionId];
        uint256 bidsLength = auctionBids[_auctionId].length;

        // If there are bids refund the last bid
        if (bidsLength > 0) {
            Bid memory lastBid = auctionBids[_auctionId][bidsLength - 1];
            if (!lastBid.from.send(lastBid.amount)) {
                revert();
            }
        }

        // approve and transfer from this contract to auction owner
        if (
            approveAndTransfer(
                address(this),
                myAuction.owner,
                myAuction.deedRepositoryAddress,
                myAuction.deedId
            )
        ) {
            auctions[_auctionId].active = false;
            emit AuctionCanceled(msg.sender, _auctionId);
        }
    }

    /**
     * @dev Finalized an ended auction
     * @dev The auction should be ended, and there should be at least one bid
     * @dev On success Deed is transfered to bidder and auction owner gets the amount
     * @param _auctionId uint ID of the created auction
     */
    function finalizeAuction(uint256 _auctionId) public {
        Auction memory myAuction = auctions[_auctionId];
        uint256 bidsLength = auctionBids[_auctionId].length;

        // 1. if auction not ended just revert
        if (block.timestamp < myAuction.blockDeadline) revert();

        if (bidsLength == 0) {
            cancelAuction(_auctionId);
        } else {
            // 2. the money goes to the auction owner
            Bid memory lastBid = auctionBids[_auctionId][bidsLength - 1];
            if (!myAuction.owner.send(lastBid.amount)) {
                revert();
            }

            // approve and transfer from this contract to the bid winner
            if (
                approveAndTransfer(
                    address(this),
                    lastBid.from,
                    myAuction.deedRepositoryAddress,
                    myAuction.deedId
                )
            ) {
                auctions[_auctionId].active = false;
                auctions[_auctionId].finalized = true;
                emit AuctionFinalized(msg.sender, _auctionId);
            }
        }
    }

    /**
     * @dev Bidder sends bid to an auction
     * @dev Auction should be active and not ended
     * @dev Refund previous bidder if a new bid is valid and placed
     * @param _auctionId uint ID of the created auction
     */
    function bidOnAuction(uint256 _auctionId) external payable {
        uint256 amountSent = msg.value;

        // owner can't bid on their auctions
        Auction memory myAuction = auctions[_auctionId];
        if (myAuction.owner == msg.sender) revert();

        // if auction is expired
        if (block.timestamp > myAuction.blockDeadline) revert();

        uint256 bidsLength = auctionBids[_auctionId].length;
        uint256 tempAmount = myAuction.startPrice;
        Bid memory lastBid;

        // there are previous bids
        if (bidsLength > 0) {
            lastBid = auctionBids[_auctionId][bidsLength - 1];
            tempAmount = lastBid.amount;
        }

        // check if amount is greater than previous amount
        if (amountSent < tempAmount) revert();

        // refund the last bidder
        if (bidsLength > 0) {
            if (!lastBid.from.send(lastBid.amount)) {
                revert();
            }
        }

        // insert bid
        Bid memory newBid;
        newBid.from = payable(msg.sender);
        newBid.amount = amountSent;
        auctionBids[_auctionId].push(newBid);
        emit BidSuccess(msg.sender, _auctionId);
    }
}
