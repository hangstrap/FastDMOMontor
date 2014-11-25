library monitor_health_utils;

import 'package:intl/intl.dart';

String formatCurrentTime() {
  return formatTime(new DateTime.now());
}
String formatTime(DateTime time) {
  DateFormat df = new DateFormat("yMd-HHmmss");
  return df.format(time.toUtc());
}
