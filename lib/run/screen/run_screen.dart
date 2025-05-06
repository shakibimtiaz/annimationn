import 'package:annimationn/run/controller/run_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class RunningScreen extends StatelessWidget {
  const RunningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final RunningController controller = Get.put(RunningController());

    return Scaffold(
      appBar: AppBar(title: const Text('Projekt Stride')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation section
            Obx(() {
              if (controller.isRunning.value && !controller.isPaused.value) {
                if (controller.isClimbing.value) {
                  return Lottie.asset('assets/climbing.json', height: 200);
                } else {
                  return Lottie.asset('assets/running.json', height: 200);
                }
              } else {
                return Lottie.asset(
                  'assets/running.json',
                  height: 200,
                  frameRate: FrameRate.max,
                  animate: false,
                );
              }
            }),
            const SizedBox(height: 20),

            // Distance
            // Distance
            Obx(
              () => Text(
                'Distance: ${controller.distance.value.toStringAsFixed(0)} m',
                style: const TextStyle(fontSize: 24),
              ),
            ),

            const SizedBox(height: 10),

            // Time
            Obx(
              () => Text(
                'Time: ${controller.formattedTime}',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(height: 10),

            // Elevation Gain
            Obx(
              () => Text(
                'Elevation Gain: ${controller.elevationGain.value.toStringAsFixed(2)} m',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(height: 40),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Obx(
                  () => ElevatedButton(
                    onPressed:
                        controller.isRunning.value && !controller.isPaused.value
                            ? controller.pauseRun
                            : controller.startRun,
                    child: Text(
                      controller.isRunning.value
                          ? (controller.isPaused.value ? 'Resume' : 'Pause')
                          : 'Start',
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: controller.stopRun,
                  child: const Text('Stop'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
