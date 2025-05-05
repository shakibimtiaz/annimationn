import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Projekt Stride',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const RunningScreen(),
    );
  }
}

class RunningController extends GetxController {
  // State variables
  var isRunning = false.obs;
  var isPaused = false.obs;
  var distance = 0.0.obs; // Distance in meters
  var elapsedTime = 0.obs; // Time in seconds
  var lastPosition = Rxn<Position>(); // Last known position
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _requestLocationPermission();
  }

  // Request location permission
  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar('Error', 'Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar('Error', 'Location permission denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar('Error', 'Location permission permanently denied.');
      return;
    }
  }

  // Start or resume the run
  void startRun() async {
    if (!isRunning.value) {
      isRunning.value = true;
      lastPosition.value = await Geolocator.getCurrentPosition();
      _startTimer();
      _startLocationTracking();
    } else if (isPaused.value) {
      isPaused.value = false;
      lastPosition.value = await Geolocator.getCurrentPosition();
      _startTimer();
      _startLocationTracking();
    }
  }

  // Pause the run
  void pauseRun() {
    isPaused.value = true;
    _timer?.cancel();
    Geolocator.getPositionStream().listen(null).cancel();
  }

  // Stop the run
  void stopRun() {
    isRunning.value = false;
    isPaused.value = false;
    distance.value = 0.0;
    elapsedTime.value = 0;
    lastPosition.value = null;
    _timer?.cancel();
    Geolocator.getPositionStream().listen(null).cancel();
  }

  // Start the timer
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsedTime.value++;
    });
  }

  // Start tracking location and calculating distance
  void _startLocationTracking() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (lastPosition.value != null && !isPaused.value) {
        double distanceInMeters = Geolocator.distanceBetween(
          lastPosition.value!.latitude,
          lastPosition.value!.longitude,
          position.latitude,
          position.longitude,
        );
        distance.value += distanceInMeters;
      }
      lastPosition.value = position;
    });
  }

  // Format time as HH:MM:SS
  String get formattedTime {
    int hours = elapsedTime.value ~/ 3600;
    int minutes = (elapsedTime.value % 3600) ~/ 60;
    int seconds = elapsedTime.value % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}

class RunningScreen extends StatelessWidget {
  const RunningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RunningController());

    return Scaffold(
      appBar: AppBar(title: const Text('Projekt Stride')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation
            Obx(() => controller.isRunning.value && !controller.isPaused.value
                ? Lottie.asset('assets/running.json', height: 200)
                : Lottie.asset('assets/running.json', height: 200, frameRate: FrameRate.max, animate: false)),
            const SizedBox(height: 20),
            // Distance
            Obx(() => Text(
                  'Distance: ${(controller.distance.value / 1000).toStringAsFixed(2)} km',
                  style: const TextStyle(fontSize: 24),
                )),
            const SizedBox(height: 20),
            // Timer
            Obx(() => Text(
                  'Time: ${controller.formattedTime}',
                  style: const TextStyle(fontSize: 24),
                )),
            const SizedBox(height: 40),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Obx(() => ElevatedButton(
                      onPressed: controller.isRunning.value && !controller.isPaused.value
                          ? controller.pauseRun
                          : controller.startRun,
                      child: Text(controller.isRunning.value
                          ? (controller.isPaused.value ? 'Resume' : 'Pause')
                          : 'Start'),
                    )),
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