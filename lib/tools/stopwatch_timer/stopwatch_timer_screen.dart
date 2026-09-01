import 'package:flutter/material.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'stopwatch_timer_controller.dart';

class StopwatchTimerScreen extends StatefulWidget {
  const StopwatchTimerScreen({super.key});

  @override
  State<StopwatchTimerScreen> createState() => _StopwatchTimerScreenState();
}

class _StopwatchTimerScreenState extends State<StopwatchTimerScreen> {
  late final StopwatchTimerController controller;

  @override
  void initState() {
    super.initState();
    controller = StopwatchTimerController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: '秒表与倒计时',
    child: AnimatedBuilder(
      animation: controller,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SegmentedButton<TimerToolMode>(
            segments: const [
              ButtonSegment(value: TimerToolMode.stopwatch, label: Text('秒表')),
              ButtonSegment(value: TimerToolMode.countdown, label: Text('倒计时')),
            ],
            selected: {controller.mode},
            onSelectionChanged: (value) => controller.setMode(value.first),
          ),
          const SizedBox(height: 28),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatTimerDuration(controller.displayed),
              style: const TextStyle(
                fontSize: 46,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (controller.mode == TimerToolMode.countdown && !controller.running)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [1, 5, 10, 25, 60]
                  .map(
                    (minutes) => ChoiceChip(
                      label: Text('$minutes 分钟'),
                      selected:
                          controller.countdownDuration.inMinutes == minutes,
                      onSelected: (_) =>
                          controller.setCountdownMinutes(minutes),
                    ),
                  )
                  .toList(),
            ),
          if (controller.mode == TimerToolMode.stopwatch)
            Card(
              elevation: 0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 180,
                  maxHeight: 280,
                ),
                child: controller.laps.isEmpty
                    ? const Center(
                        child: Text(
                          '开始计时后可记录计次',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: controller.laps.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) => ListTile(
                          title: Text('计次 ${controller.laps.length - index}'),
                          trailing: Text(
                            formatTimerDuration(controller.laps[index]),
                          ),
                        ),
                      ),
              ),
            )
          else
            const SizedBox(
              height: 180,
              child: Center(
                child: Icon(
                  Icons.timer_outlined,
                  size: 64,
                  color: AppColors.muted,
                ),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: controller.toggle,
            child: Text(controller.running ? '暂停' : '开始'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      controller.mode == TimerToolMode.stopwatch &&
                          controller.running
                      ? controller.addLap
                      : null,
                  child: const Text('计次'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.reset,
                  child: const Text('重置'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
