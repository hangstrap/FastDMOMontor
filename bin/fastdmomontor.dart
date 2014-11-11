import "dart:async";
import "dart:core";
import "dart:io";

import 'package:intl/intl.dart';

import 'package:http/http.dart' as http;

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
    print( e);
    completer.complete( "error");
   });

 
  return completer.future;
}

void processStatus( Server server, String status){
  
  print( "${server.name} old status = ${server.status} new status= ${status}");
  switch( status){
    case "OK": server.status="OK"; break;
    case "error": server.status="error"; break;
    default:
      if( status != server.status ){
        print( "had a change in status");
        downloadCurrentLog( server);
      }
      break;        
  }
  server.status = status;
 
}

void downloadCurrentLog( Server server){
  

  
  Uri url = new Uri.http(server.url, "/browseDirectories", {"path":"\log\fastdmo.${server.name}.log"});

  print( "about to download log for ${server.name} ${url}");
  
  http.get( url).then( (response) {
    if( response.statusCode == 200){
         

        String now= formatCurrentTime();      
        String fileName = "/Temp/fastDMOMonitoring/${server.name}-${now.toString()}.log";
        
        File output = new File( fileName);
        
        output.writeAsString( response.body)
        .then( (file)=>print( "Downloaded log as ${fileName}"))
        .catchError( (e)=>print( "Could not download file ${e}"));
         
            
    }else{
      throw "could not download log file";
    }
    print( response.statusCode);
  })
  .catchError( (e){ 
    print( e);
   });

  
}

String formatCurrentTime(){
  DateTime now = new DateTime.now().toUtc();
  DateFormat df = new DateFormat( DateFormat.YEAR_NUM_MONTH_DAY+ '-' +DateFormat.HOUR24_MINUTE_SECOND);
  return df.format( now);
}

void scanServers() {
  print( "Scannning servers");
  



  servers.forEach((server) {
    getStatus(server).then( (result) => processStatus( server, result));
  });



}

void main() {

  Duration duration = new Duration( seconds:15);
  Timer timer = new Timer.periodic( duration, (t)=>scanServers());
  
}