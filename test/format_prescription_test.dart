import 'package:flutter_test/flutter_test.dart';
import 'package:my_fit_notebook_mobile/utils/formatters.dart';

void main() {
  test('single rep count', () {
    expect(formatPrescription(2, 10, null), '(2x10)');
  });

  test('rep range', () {
    expect(formatPrescription(2, 10, 12), '(2x10-12)');
  });

  test('range collapses when max equals min', () {
    expect(formatPrescription(3, 8, 8), '(3x8)');
  });

  test('range ignored when max below min', () {
    expect(formatPrescription(3, 8, 5), '(3x8)');
  });

  test('empty when sets or reps missing / non-positive', () {
    expect(formatPrescription(null, 10, null), '');
    expect(formatPrescription(2, null, null), '');
    expect(formatPrescription(0, 10, null), '');
    expect(formatPrescription(2, 0, null), '');
  });
}
