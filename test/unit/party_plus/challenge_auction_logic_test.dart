import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/party_plus/logic/challenge_auction_logic.dart';

void main() {
  group('normalizeBidRange', () {
    test('uses challenge minimum when configured minimum is lower', () {
      final range = normalizeBidRange(
        configuredMinBid: 1,
        configuredMaxBid: 20,
        challengeMinBid: 3,
      );

      expect(range.minBid, 3);
      expect(range.maxBid, 20);
    });

    test('fixes invalid max value smaller than min', () {
      final range = normalizeBidRange(
        configuredMinBid: 8,
        configuredMaxBid: 3,
        challengeMinBid: 2,
      );

      expect(range.minBid, 8);
      expect(range.maxBid, 8);
    });
  });

  group('normalizeBidInput', () {
    test('clamps input above max to max', () {
      final bid = normalizeBidInput(
        rawInput: '99',
        fallback: 5,
        minBid: 2,
        maxBid: 12,
      );

      expect(bid, 12);
    });

    test('falls back when input is invalid', () {
      final bid = normalizeBidInput(
        rawInput: 'abc',
        fallback: 6,
        minBid: 2,
        maxBid: 12,
      );

      expect(bid, 6);
    });
  });

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
