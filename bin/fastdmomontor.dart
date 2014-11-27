library fastdmomonitor;

import "dart:async";
import "dart:core";
import "dart:io";
import "package:logging/logging.dart";

import 'server.dart';
import 'monitor_health.dart';
import 'monitor_health_utils.dart' as monitor_health_utils;

import 'package:intl/intl.dart';


Directory logDirectory = new Directory("logging");
int scancount = 0;
Logger log = new Logger("fastdmomonitor");

List<Server> servers = [new Server("ec.prod", "isapps:M3ts3rv1c3@fastdmo-ec.amazon.metcloudservices.com:8080"), 
                        new Server("gfs.prod", "isapps:M3ts3rv1c3@fastdmo-gfs.amazon.metcloudservices.com:8080"), 
                        new Server("ec.preprod", "isapps:M3ts3rv1c3@fastdmo-ec.amazon-preprod.metcloudservices.com:8080"), 
                        new Server("gfs.preprod", "isapps:M3ts3rv1c3@fastdmo-gfs.amazon-preprod.metcloudservices.com:8080"), 
//                        new Server("localhost", "isapps:Metservice@localhost:8090"),
                        ];

List<MonitorHealth> healthMonitors = [];

DateFormat df = new DateFormat("d-HHmmss");

void setUpLogger() {

  logDirectory.create();
  File logger = new File("${logDirectory.path}/logger.log");
  logger.create(recursive: true);

  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((LogRecord rec) {

    String msg = '${rec.level.name}: ${monitor_health_utils.formatTime( rec.time.toUtc())} UTC  (${df.format( rec.time)} NZT) : ${rec.message}';
    logger.writeAsString(msg + "\n", mode: FileMode.APPEND, flush: true);
    print(msg);
  });
}

void hadFailure( Server server, String status, File logFile, File htmlFile){
  
}
void scanServers(){
  if (scancount % 10 == 0) {
      log.info("Scannning servers ${scancount} attempt");
    }
    scancount++;
  
  healthMonitors.forEach( (healthMonitor) => healthMonitor.scanServer( hadFailure));
}

void main() {

  setUpLogger();
  Duration scanDuration = new Duration(seconds: 15);
  
  servers.forEach( (Server server) {
    
    healthMonitors.add( new MonitorHealth(logDirectory, server));
    log.info("Starting up monitor for ${server.name}");
  });
  
  new Timer.periodic(scanDuration, (t) => scanServers());  

}
