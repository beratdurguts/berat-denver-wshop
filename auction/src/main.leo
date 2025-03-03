program auction_testnet_beratdrgt.aleo {

    record Bid {
        owner: address,
        bidder: address,
        amount: u64,
        is_winner: bool,
    }

    transition place_bid(bidder: address, amount: u64) -> Bid {
        // Ensure the caller is the auction bidder.
        assert_eq(self.caller, bidder);
        // Return a new 'Bid' record for the auction bidder.
        return Bid {
            owner: aleo1zsdc7ssp9cucmscz6yhxj40u4g3ddz6ncl02xnyka4w8705j3gxqwnv7x4,
            bidder: bidder,
            amount: amount,
            is_winner: false,
        };
    }


    transition resolve(first: Bid, second: Bid) -> Bid {
        // Ensure the caller is the auctioneer.
        assert_eq(self.caller, aleo1zsdc7ssp9cucmscz6yhxj40u4g3ddz6ncl02xnyka4w8705j3gxqwnv7x4);
        // Resolve the winner of the auction.
        if (first.amount >= second.amount) {
            return first;
        } else {
            return second;
        }
    }


    transition finish(bid: Bid) -> Bid {
        // Ensure the caller is the auctioneer.
        assert_eq(self.caller, aleo1zsdc7ssp9cucmscz6yhxj40u4g3ddz6ncl02xnyka4w8705j3gxqwnv7x4);
        // Return 'is_winner' as 'true' in the winning 'Bid'.
        return Bid {
            owner: bid.bidder,
            bidder: bid.bidder,
            amount: bid.amount,
            is_winner: true,
        };
    }
}