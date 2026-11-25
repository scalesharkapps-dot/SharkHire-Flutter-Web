import 'package:flutter_test/flutter_test.dart';
import 'package:sharkhire/features/subscription/presentation/providers/application_quota.dart';

void main() {
  test('5 applications per plan, counted down to zero', () {
    const fresh = ApplicationQuota(used: 0, isPremium: false);
    expect(fresh.limit, 5);
    expect(fresh.left, 5);
    expect(fresh.isUsedUp, isFalse);

    const three = ApplicationQuota(used: 3, isPremium: true);
    expect(three.left, 2);
    expect(three.isUsedUp, isFalse);

    const done = ApplicationQuota(used: 5, isPremium: false);
    expect(done.left, 0);
    expect(done.isUsedUp, isTrue);

    // More applications than the limit never shows a negative count.
    const over = ApplicationQuota(used: 7, isPremium: true);
    expect(over.left, 0);
    expect(over.isUsedUp, isTrue);
  });
}
