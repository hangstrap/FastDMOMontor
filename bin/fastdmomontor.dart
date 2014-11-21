import "dart:async";
import "dart:core";
import "dart:io";
import "package:logging/logging.dart";

import 'package:intl/intl.dart';

import 'package:http/http.dart' as http;

Directory logDirectory = new Directory("logging");

int scancount = 0;
Logger log = new Logger("FastDmoMonitor");

class Server {
  String name;
  String url;
  String status;
  Server(this.name, this.url);
}

List<Server> servers = [new Server("ec.prod", "isapps:M3ts3rv1c3@fastdmo-ec.amazon.metcloudservices.com:8080"), 
                        new Server("gfs.prod", "isapps:M3ts3rv1c3@fastdmo-gfs.amazon.metcloudservices.com:8080"), 
                        new Server("ec.preprod", "isapps:M3ts3rv1c3@fastdmo-ec.amazon-preprod.metcloudservices.com:8080"), 
                        new Server("gfs.preprod", "isapps:M3ts3rv1c3@fastdmo-gfs.amazon-preprod.metcloudservices.com:8080"), 
                        new Server("localhost", "isapps:Metservice@localhost:8090"),];

Future<String> getStatus(Server server) {

  Completer completer = new Completer();

  Uri url = new Uri.http(server.url, "health");
  http.get(url).then((response) {
    completer.complete(response.body);
  }).catchError((e) {
    log.info("Could not access server ${server.name} ${e}");
    completer.complete("error");
  });


  return completer.future;
}

void processStatus(Server server, String status) {

  log.fine("${server.name} old status = ${server.status} new status= ${status}");
  if (server.status != null) {
    if (status != server.status) {
      log.info("Server ${server.name} moved to a new state: old status = ${server.status} new status= ${status}");
      switch (status) {
        case "OK":
          server.status = "OK";
          break;
        case "error":
          server.status = "error";
          break;
        default:
          downloadCurrentLog(server, status);
          downloadAlertPage(server, status);
          break;
      }
    }
  }
  server.status = status;

}
void downloadAlertPage(Server server, String status) {

  Uri url = new Uri.http(server.url, "alerts/allAlerts", {
    "order": "INITIAL"
  });
  log.info("about to download alerts for ${server.name} ${url}");

  File output = createFileName( server, status, "html");
  downloadAndSaveToDisk( url,  output);
}
void downloadCurrentLog(Server server, String status) {

  Uri url = new Uri.http(server.url, "/downloadFile", {
    "path": "log/fastdmo.${server.name}.log"
  });

  log.info("about to download log for ${server.name} ${url}");

  File output = createFileName( server, status, "log");
  downloadAndSaveToDisk( url,  output);

}
void downloadAndSaveToDisk( Uri url, File output){

  http.get(url).then((response) {
    if (response.statusCode == 200) {

      output.writeAsString(response.body).then((file) => log.info("Saved log as ${output}")).catchError((e) => log.warning("Could not save file ${e}"));


    } else {
      throw "Website returned status code of ${response.statusCode}";
    }
  }).catchError((e) {
    log.warning("could not download file ${e}");
  });

}
File createFileName( Server server, String status, String extension){
  
    String now = formatCurrentTime();
    status = status.replaceAll( " ", "-");
    String fileName = "${logDirectory.path}/${server.name}-${status}-${now.toString()}.${extension}";
    File output = new File(fileName);
    return output;
}

String formatCurrentTime() {
  return formatTime(new DateTime.now());
}
String formatTime(DateTime time) {
  DateFormat df = new DateFormat("yMd-hhmmss");
  return df.format(time.toUtc());
}

void scanServers() {
  if (scancount % 10 == 0) {
    log.info("Scannning servers ${scancount} attempt");
  }
  scancount++;

  servers.forEach((server) {
    getStatus(server).then((result) => processStatus(server, result));
  });



}

void setUpLogger() {

  logDirectory.create();
  File logger = new File("${logDirectory.path}/logger.log");
  logger.create(recursive: true);

  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((LogRecord rec) {

    String msg = '${rec.level.name}: ${formatTime( rec.time)}: ${rec.message}';
    logger.writeAsString(msg + "\n", mode: FileMode.APPEND, flush: true);
    print(msg);
  });


}

void main() {

  setUpLogger();
  Duration duration = new Duration(seconds: 15);
  Timer timer = new Timer.periodic(duration, (t) => scanServers());

  log.info("Starting up monitor");

}
