import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/party_plus/logic/challenge_auction_logic.dart';

void main() {
  group('resolveAuctionWinner', () {
    test('picks lowest bid as winner', () {
      final resolution = resolveAuctionWinner(
        bids: [3, 1, 4, 2],
        random: Random(1),
      );

      expect(resolution.winningBid, 1);
      expect(resolution.winnerIndex, 1);
    });

    test('breaks tie among lowest bids with random index', () {
      final resolution = resolveAuctionWinner(
        bids: [2, 1, 1, 3],
        random: Random(2),
      );

      expect(resolution.winningBid, 1);
      expect([1, 2].contains(resolution.winnerIndex), true);
    });

    test('throws on empty bids', () {
      expect(
        () => resolveAuctionWinner(bids: const [], random: Random(1)),
        throwsArgumentError,
      );
    });
  });
}
