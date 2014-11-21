library fastdmomonitor;

import "dart:async";
import "dart:core";
import "dart:io";
import "package:logging/logging.dart";

import 'server.dart';
import 'monitor_health.dart';
import 'monitor_health_utils.dart' as monitor_health_utils;


Directory logDirectory = new Directory("logging");


Logger log = new Logger("fastdmomonitor");

List<Server> servers = [new Server("ec.prod", "isapps:M3ts3rv1c3@fastdmo-ec.amazon.metcloudservices.com:8080"), 
                        new Server("gfs.prod", "isapps:M3ts3rv1c3@fastdmo-gfs.amazon.metcloudservices.com:8080"), 
                        new Server("ec.preprod", "isapps:M3ts3rv1c3@fastdmo-ec.amazon-preprod.metcloudservices.com:8080"), 
                        new Server("gfs.preprod", "isapps:M3ts3rv1c3@fastdmo-gfs.amazon-preprod.metcloudservices.com:8080"), 
                        new Server("localhost", "isapps:Metservice@localhost:8090"),];


void setUpLogger() {

  logDirectory.create();
  File logger = new File("${logDirectory.path}/logger.log");
  logger.create(recursive: true);

  Logger.root.level = Level.FINE;
  Logger.root.onRecord.listen((LogRecord rec) {

    String msg = '${rec.level.name}: ${monitor_health_utils.formatTime( rec.time)}: ${rec.message}';
    logger.writeAsString(msg + "\n", mode: FileMode.APPEND, flush: true);
    print(msg);
  });


}

void main() {

  setUpLogger();
  Duration duration = new Duration(seconds: 15);
  MonitorHealth monitorHealth = new MonitorHealth(logDirectory, servers);
  Timer timer = new Timer.periodic(duration, (t) => monitorHealth.scanServers());

  log.info("Starting up monitor");

}
