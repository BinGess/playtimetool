import 'dart:math';

class AuctionResolution {
  const AuctionResolution({
    required this.winnerIndex,
    required this.winningBid,
  });

  final int winnerIndex;
  final int winningBid;
}

class BidRange {
  const BidRange({
    required this.minBid,
    required this.maxBid,
  });

  final int minBid;
  final int maxBid;
}

BidRange normalizeBidRange({
  required int configuredMinBid,
  required int configuredMaxBid,
  required int challengeMinBid,
}) {
  final minBid = max(1, max(configuredMinBid, challengeMinBid));
  final maxBid = max(minBid, configuredMaxBid);
  return BidRange(minBid: minBid, maxBid: maxBid);
}

int normalizeBidInput({
  required String rawInput,
  required int fallback,
  required int minBid,
  required int maxBid,
}) {
  final parsed = int.tryParse(rawInput.trim()) ?? fallback;
  return parsed.clamp(minBid, maxBid).toInt();
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
