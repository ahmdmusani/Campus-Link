import 'ride_model.dart';
import 'ride_request_model.dart';

class DriverPendingRequestItem {
  final RideRequestModel request;
  final RideModel ride;

  const DriverPendingRequestItem({
    required this.request,
    required this.ride,
  });
}
