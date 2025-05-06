import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class RunningController extends GetxController {
  var isRunning = false.obs;
  var isPaused = false.obs;
  var distance = 0.0.obs; // in meters
  var elapsedTime = 0.obs; // in seconds
  var elevationGain = 0.0.obs; // in meters
  var isClimbing = false.obs;

  var lastPosition = Rxn<Position>();
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _requestLocationPermission();
  }

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

  void pauseRun() {
    isPaused.value = true;
    _timer?.cancel();
    Geolocator.getPositionStream().listen(null).cancel();
  }

  void stopRun() {
    isRunning.value = false;
    isPaused.value = false;
    distance.value = 0.0;
    elapsedTime.value = 0;
    elevationGain.value = 0.0;
    isClimbing.value = false;
    lastPosition.value = null;
    _timer?.cancel();
    Geolocator.getPositionStream().listen(null).cancel();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsedTime.value++;
    });
  }

  void _startLocationTracking() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (lastPosition.value != null && !isPaused.value) {
        // Calculate distance
        double distanceInMeters = Geolocator.distanceBetween(
          lastPosition.value!.latitude,
          lastPosition.value!.longitude,
          position.latitude,
          position.longitude,
        );
        distance.value += distanceInMeters;

        // Calculate elevation gain
        double lastAltitude = lastPosition.value!.altitude;
        double newAltitude = position.altitude;
        double gain = newAltitude - lastAltitude;
        if (gain > 0) {
          elevationGain.value += gain;
          isClimbing.value = true;
        } else {
          isClimbing.value = false;
        }
      }
      lastPosition.value = position;
    });
  }

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
