import "dart:async";
import "dart:core";
import "dart:io";
import "package:logging/logging.dart";

import 'package:intl/intl.dart';

import 'package:http/http.dart' as http;

Directory logDirectory = new Directory( "logging");


Logger log = new Logger( "FastDmoMonitor");

class Server {
  String name;
  String url;
  String status;
  Server(this.name, this.url);
}

List<Server> servers = [new Server("ec.prod", "isapps:M3ts3rv1c3@fastdmo-ec.amazon.metcloudservices.com:8080"), 
                        new Server("gfs.prod", "isapps:M3ts3rv1c3@fastdmo-gfs.amazon.metcloudservices.com:8080"), 
                        new Server("ec.preprod", "isapps:M3ts3rv1c3@fastdmo-gfs.amazon-preprod.metcloudservices.com:8080"), 
                        new Server("gfs.preprod", "isapps:M3ts3rv1c3@fastdmo-gfs.amazon-preprod.metcloudservices.com:8080"),
                    new Server("localhost", "isapps:Metservice@localhost:8090"),
];

Future<String> getStatus(Server server) {
  
  Completer completer = new Completer();
  
  Uri url = new Uri.http(server.url, "health");
  http.get( url).then( (response) {
    completer.complete( response.body);
  })
  .catchError( (e){ 
    log.info ( "Could not access server ${server.name} ${e}");
    completer.complete( "error");
   });

 
  return completer.future;
}

void processStatus( Server server, String status){
  
  log.fine( "${server.name} old status = ${server.status} new status= ${status}");
  switch( status){
    case "OK": server.status="OK"; break;
    case "error": server.status="error"; break;
    default:
      if( status != server.status ){
        log.info( "${server.name} old status = ${server.status} new status= ${status} - server moved to a fault state");
        downloadCurrentLog( server);
      }
      break;        
  }
  server.status = status;
 
}

void downloadCurrentLog( Server server){
  

  
  Uri url = new Uri.http(server.url, "/downloadFile", {"path":"log/fastdmo.${server.name}.log"});

  log.info( "about to download log for ${server.name} ${url}");
  
  http.get( url).then( (response) {
    if( response.statusCode == 200){
         

        String now= formatCurrentTime();      
        String fileName = "${logDirectory.path}/${server.name}-${now.toString()}.log";
        
        File output = new File( fileName);
        
        output.writeAsString( response.body)
        .then( (file)=> log.info( "Saved log as ${fileName}"))
        .catchError( (e)=>log.warning( "Could not save file ${e}"));
        
            
    }else{
      throw "Website returned status code of ${response.statusCode}";
    }
  })
  .catchError( (e){ 
      log.warning( "could not download file ${e}");
   });

  
}

String formatCurrentTime(){
  return formatTime(new DateTime.now() );
}
String formatTime(DateTime time){
  DateFormat df = new DateFormat( "yMd-hhmmss");
  return df.format( time.toUtc());
}

void scanServers() {
  log.fine( "Scannning servers");
  
  servers.forEach((server) {
    getStatus(server).then( (result) => processStatus( server, result));
  });



}

void setUpLogger(){
  
  logDirectory.create();
  File logger = new File( "${logDirectory.path}/logger.log");
  logger.create( recursive: true);
  
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((LogRecord rec) {
    
    String msg = '${rec.level.name}: ${formatTime( rec.time)}: ${rec.message}'; 
    logger.writeAsString( msg +"\n", mode:FileMode.APPEND, flush: true);
    print( msg);
  });


}

void main() {
  
  setUpLogger();
  Duration duration = new Duration( seconds:15);
  Timer timer = new Timer.periodic( duration, (t)=>scanServers());
  
  log.info( "Starting up monitor");
  
}