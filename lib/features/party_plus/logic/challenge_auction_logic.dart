import 'dart:math';

class AuctionResolution {
  const AuctionResolution({
    required this.winnerIndex,
    required this.winningBid,
  });

  final int winnerIndex;
  final int winningBid;
}

AuctionResolution resolveAuctionWinner({
  required List<int> bids,
  required Random random,
}) {
  if (bids.isEmpty) {
    throw ArgumentError('bids must not be empty');
  }

  final winningBid = bids.reduce(min);
  final winners = <int>[];
  for (int i = 0; i < bids.length; i++) {
    if (bids[i] == winningBid) {
      winners.add(i);
    }
  }
  final winnerIndex = winners[random.nextInt(winners.length)];
  return AuctionResolution(winnerIndex: winnerIndex, winningBid: winningBid);
}
