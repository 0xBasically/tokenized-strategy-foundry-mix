// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

import {ITermAuctionOfferLocker} from "../../interfaces/term/ITermAuctionOfferLocker.sol";
import {ITermAuction} from "../../interfaces/term/ITermAuction.sol";
import {MockTermRepoLocker} from "./MockTermRepoLocker.sol";

contract MockTermAuctionOfferLocker is ITermAuctionOfferLocker {

    address public purchaseToken;
    MockTermRepoLocker internal repoLocker;
    ITermAuction internal auction;
    mapping(bytes32 => TermAuctionOffer) internal lockedOffers;
    
    constructor(ITermAuction _auction, address _repoLocker, address _purchaseToken) {
        auction = _auction;
        purchaseToken = _purchaseToken;
        repoLocker = MockTermRepoLocker(_repoLocker);
    }

    function termRepoId() external view returns (bytes32) {
        return auction.termRepoId();
    }

    function termAuctionId() external view returns (bytes32) {
        return auction.termRepoId();
    }

    function auctionStartTime() external view returns (uint256) {

    }

    function auctionEndTime() external view returns (uint256) {
        return auction.auctionEndTime();
    }

    function revealTime() external view returns (uint256) {

    }

    function termRepoServicer() external view returns (address) {

    }

    function lockedOffer(bytes32 id) external view returns (TermAuctionOffer memory) {
        return lockedOffers[id];
    }

    /// @param offerSubmissions An array of offer submissions
    /// @return A bytes32 array of unique on chain offer ids.
    function lockOffers(
        TermAuctionOfferSubmission[] calldata offerSubmissions
    ) external returns (bytes32[] memory) {
        for (uint256 i; i < offerSubmissions.length; i++) {
            TermAuctionOfferSubmission memory submission = offerSubmissions[i];
            TermAuctionOffer memory offer;
            
            offer.id = submission.id;
            offer.offeror = submission.offeror;
            offer.offerPriceHash = submission.offerPriceHash;
            offer.amount = submission.amount;
            offer.purchaseToken = submission.purchaseToken;

            lockedOffers[offer.id] = offer;

            repoLocker.lockPurchaseTokens(msg.sender, offer.amount);
        }
    }

    function fillOffer(bytes32 offerId, address receiver, uint256 fillAmount) external {
        require(lockedOffers[offerId].amount >= fillAmount);
        uint256 remainingAmount = lockedOffers[offerId].amount - fillAmount;

        lockedOffers[offerId].amount = remainingAmount;

        repoLocker.releasePurchaseTokens(receiver, remainingAmount);
    }

    function unlockOffers(bytes32[] calldata offerIds) external {
        for (uint256 i; i < offerIds.length; i++) {
            bytes32 offerId = offerIds[i];
            repoLocker.releasePurchaseTokens(msg.sender, lockedOffers[offerId].amount);
            delete lockedOffers[offerId];
        }
    }
}
