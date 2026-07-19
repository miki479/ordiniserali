import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Drives the offline banner: an order that "succeeds" while offline would
/// silently never reach the kitchen, so this needs to be impossible to miss.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  final initial = await connectivity.checkConnectivity();
  yield !initial.contains(ConnectivityResult.none);
  yield* connectivity.onConnectivityChanged.map(
    (r) => !r.contains(ConnectivityResult.none),
  );
});
