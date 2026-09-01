import 'dart:math';

import 'package:bill/tools/age_calculator/age_calculator_logic.dart';
import 'package:bill/tools/bill_split/bill_split_logic.dart';
import 'package:bill/tools/list_processor/list_processor_logic.dart';
import 'package:bill/tools/percentage_calculator/percentage_calculator_logic.dart';
import 'package:bill/tools/random_decision/random_decision_logic.dart';
import 'package:bill/tools/stopwatch_timer/stopwatch_timer_controller.dart';
import 'package:bill/tools/tally_counter/tally_counter_controller.dart';
import 'package:bill/tools/tally_counter/tally_counter_model.dart';
import 'package:bill/tools/tally_counter/tally_counter_service.dart';
import 'package:bill/tools/text_diff/text_diff_logic.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryTallyService extends TallyCounterService {
  _MemoryTallyService([List<TallyCounter>? initial])
    : values = List.of(initial ?? const []);

  List<TallyCounter> values;

  @override
  Future<List<TallyCounter>> load() async => List.of(values);

  @override
  Future<void> save(List<TallyCounter> counters) async {
    values = List.of(counters);
  }
}

void main() {
  group('percentage calculator', () {
    test('calculates a normal percentage', () {
      expect(percentageOf(20, 80), 25);
    });

    test('rejects zero total and non-finite values', () {
      expect(percentageOf(1, 0), isNull);
      expect(percentageOf(double.nan, 10), isNull);
    });

    test('supports increases and decreases', () {
      expect(applyPercentageChange(100, 15), closeTo(115, .000001));
      expect(applyPercentageChange(100, -20), closeTo(80, .000001));
    });

    test('enforces discount boundaries', () {
      expect(discountedPrice(299, 8.5), closeTo(254.15, .001));
      expect(discountedPrice(100, 10), 100);
      expect(discountedPrice(100, 10.1), isNull);
    });
  });

  group('bill split', () {
    test('splits total and extra fee', () {
      expect(splitBill(total: 360, people: 4, extraFee: 8), 92);
    });

    test('rejects invalid people count', () {
      expect(splitBill(total: 100, people: 0), isNull);
      expect(splitBill(total: 100, people: 10001), isNull);
    });

    test('rejects negative and non-finite amounts', () {
      expect(splitBill(total: -1, people: 1), isNull);
      expect(splitBill(total: double.infinity, people: 1), isNull);
    });

    test('supports zero total at upper people boundary', () {
      expect(splitBill(total: 0, people: 10000), 0);
    });
  });

  group('age calculator', () {
    test('calculates age before birthday', () {
      final result = calculateAge(DateTime(2000, 6, 15), DateTime(2026, 6, 14));
      expect(result?.years, 25);
      expect(result?.daysUntilBirthday, 1);
    });

    test('calculates exact birthday', () {
      final result = calculateAge(DateTime(2000, 6, 15), DateTime(2026, 6, 15));
      expect(result?.years, 26);
      expect(result?.daysUntilBirthday, 0);
    });

    test('rejects future and unsupported old dates', () {
      expect(calculateAge(DateTime(2030), DateTime(2026)), isNull);
      expect(calculateAge(DateTime(1899), DateTime(2026)), isNull);
    });

    test('handles leap-day birthdays in non-leap years', () {
      final result = calculateAge(DateTime(2000, 2, 29), DateTime(2025, 2, 28));
      expect(result?.years, 25);
      expect(result?.daysUntilBirthday, 0);
    });
  });

  group('stopwatch and countdown', () {
    test('formats elapsed duration', () {
      expect(
        formatTimerDuration(
          const Duration(hours: 1, minutes: 2, seconds: 3, milliseconds: 450),
        ),
        '01:02:03.45',
      );
    });

    test('clamps negative display values', () {
      expect(formatTimerDuration(const Duration(seconds: -1)), '00:00:00.00');
    });

    test('clamps countdown minute boundaries', () {
      final controller = StopwatchTimerController()
        ..setMode(TimerToolMode.countdown);
      controller.setCountdownMinutes(0);
      expect(controller.countdownDuration, const Duration(minutes: 1));
      controller.setCountdownMinutes(99999);
      expect(controller.countdownDuration, const Duration(hours: 24));
      controller.dispose();
    });

    test('changes running state and resets safely', () {
      final controller = StopwatchTimerController();
      controller.start();
      expect(controller.running, isTrue);
      controller.pause();
      expect(controller.running, isFalse);
      controller.reset();
      expect(controller.displayed, Duration.zero);
      controller.dispose();
    });
  });

  group('random decision', () {
    test('selects from valid options', () {
      expect(chooseRandom(['唯一选项'], random: Random(1)), '唯一选项');
    });

    test('ignores empty options', () {
      expect(chooseRandom(['', '  '], random: Random(1)), isNull);
    });

    test('generates values inside an inclusive range', () {
      final value = secureRandomInt(-2, 2, random: Random(2));
      expect(value, inInclusiveRange(-2, 2));
    });

    test('rejects reversed and excessive ranges', () {
      expect(secureRandomInt(2, 1), isNull);
      expect(secureRandomInt(0, 1000000001), isNull);
    });
  });

  group('tally counter', () {
    test('restores persisted counters', () async {
      final service = _MemoryTallyService([
        const TallyCounter(id: 'a', name: '测试', value: 3),
      ]);
      final controller = TallyCounterController(service: service);
      await controller.initialize();
      expect(controller.selected?.value, 3);
    });

    test('uses safe defaults for empty storage', () async {
      final controller = TallyCounterController(service: _MemoryTallyService());
      await controller.initialize();
      expect(controller.counters, hasLength(3));
    });

    test('adds, changes and resets a counter', () async {
      final service = _MemoryTallyService();
      final controller = TallyCounterController(service: service);
      await controller.initialize();
      expect(await controller.add('新项目'), isTrue);
      await controller.change(1);
      expect(controller.selected?.value, 1);
      await controller.reset();
      expect(controller.selected?.value, 0);
    });

    test('rejects invalid persisted and user values', () async {
      expect(
        TallyCounter.tryFromJson({'id': '../x', 'name': 'x', 'value': 1}),
        isNull,
      );
      final controller = TallyCounterController(service: _MemoryTallyService());
      await controller.initialize();
      expect(await controller.add(''), isFalse);
      expect(await controller.add('x' * 31), isFalse);
    });
  });

  group('text diff', () {
    test('keeps identical lines', () {
      final result = diffLines('a\nb', 'a\nb');
      expect(result.every((line) => line.type == DiffType.unchanged), isTrue);
    });

    test('marks removed and added lines', () {
      final result = diffLines('a\nold', 'a\nnew');
      expect(
        result.where((line) => line.type == DiffType.removed).single.text,
        'old',
      );
      expect(
        result.where((line) => line.type == DiffType.added).single.text,
        'new',
      );
    });

    test('returns no rows for two empty inputs', () {
      expect(diffLines('', ''), isEmpty);
    });

    test('caps each side at 200 lines', () {
      final text = List.generate(250, (index) => '$index').join('\n');
      expect(diffLines(text, text), hasLength(200));
    });
  });

  group('list processor', () {
    test('parses lines and both comma styles', () {
      expect(parseList('a,b，c\nd'), ['a', 'b', 'c', 'd']);
    });

    test('sorts without changing the original list', () {
      final source = ['b', 'A'];
      expect(sortList(source), ['A', 'b']);
      expect(source, ['b', 'A']);
    });

    test('removes duplicates while preserving order', () {
      expect(uniqueList(['a', 'b', 'a']), ['a', 'b']);
    });

    test('rejects excessive input and preserves shuffled members', () {
      expect(parseList('x' * 50001), isEmpty);
      expect(shuffleList(['a', 'b', 'c'], random: Random(1)).toSet(), {
        'a',
        'b',
        'c',
      });
    });
  });
}
