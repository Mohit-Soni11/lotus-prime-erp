import 'dart:async';
import 'package:intl/intl.dart';

// ✅ DATA MODEL
class DateCardModel {
  final String day;
  final String date;
  final String time;

  const DateCardModel({
    required this.day,
    required this.date,
    required this.time,
  });

  factory DateCardModel.empty() {
    return const DateCardModel(day: "--", date: "--", time: "--:--");
  }
}

// ✅ LOGIC CONTROLLER
class DateCardLogic {
  final StreamController<DateCardModel> _controller =
      StreamController<DateCardModel>.broadcast();
  Timer? _timer;

  Stream<DateCardModel> get timeStream => _controller.stream;

  void init() {
    _emitTime(); // Turant time dikhao wait mat karo
    // Periodic timer start
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _emitTime();
    });
  }

  void dispose() {
    _timer?.cancel();
    if (!_controller.isClosed) {
      _controller.close();
    }
  }

  void _emitTime() {
    try {
      if (_controller.isClosed) return;

      final DateTime now = DateTime.now();

      final model = DateCardModel(
        day: DateFormat('EEEE').format(now).toUpperCase(),
        date: DateFormat('dd MMM yyyy')
            .format(now), // Short Month (Feb) looks better
        time: DateFormat('hh:mm a').format(now),
      );

      _controller.add(model);
    } catch (e) {
      // Fail silently in stream
      if (!_controller.isClosed) _controller.add(DateCardModel.empty());
    }
  }

  DateCardModel get initialData {
    try {
      final DateTime now = DateTime.now();
      return DateCardModel(
        day: DateFormat('EEEE').format(now).toUpperCase(),
        date: DateFormat('dd MMM yyyy').format(now),
        time: DateFormat('hh:mm a').format(now),
      );
    } catch (e) {
      return DateCardModel.empty();
    }
  }
}
