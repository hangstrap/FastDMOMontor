library monitor_health;

import "dart:async";
import "dart:core";
import "dart:io";
import "package:logging/logging.dart";
import 'package:http/http.dart' as http;
import '../lib/server.dart';
import 'monitor_health_utils.dart' as monitor_health_utils;

//Callback  
typedef void HadFailure( Server server, String status, File logFile, File htmlFile);


class MonitorHealth {

  Logger log = new Logger("monitor_health");
  final Directory logDirectory;
  final Server server;
  final HadFailure hadFailureCallback;

  MonitorHealth( this.logDirectory, this.server, this.hadFailureCallback);
  

/**Public access through this method*/
  void scanServer( ) {
    getStatus(server).then((result) => processStatus(server, result));
   
  }



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
            File logFile = downloadCurrentLog(server, status);
            File htmlFile = downloadAlertPage(server, status);
            hadFailureCallback( server, status, logFile, htmlFile);
            break;
        }
      }
    }
    server.status = status;

  }
  
  File downloadAlertPage(Server server, String status) {

    Uri url = new Uri.http(server.url, "alerts/allAlerts", {
      "order": "INITIAL"
    });
    log.info("about to download alerts for ${server.name} ${url}");

    File output = createFileName(server, status, "html");
    downloadAndSaveToDisk(url, output);
    return output;
  }
  
  File downloadCurrentLog(Server server, String status) {

    Uri url = new Uri.http(server.url, "/downloadFile", {
      "path": "log/fastdmo.${server.name}.log"
    });

    log.info("about to download log for ${server.name} ${url}");

    File output = createFileName(server, status, "log");
    downloadAndSaveToDisk(url, output);
    return output;
  }

  void downloadAndSaveToDisk(Uri url, File output) {

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
  File createFileName(Server server, String status, String extension) {

    String now = monitor_health_utils.formatCurrentTime();
    status = status.replaceAll(" ", "-");
    String fileName = "${logDirectory.path}/${server.name}-${status}-${now.toString()}.${extension}";
    File output = new File(fileName);
    return output;
  }


}
