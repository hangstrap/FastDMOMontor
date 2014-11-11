//import "dart:async";
import "dart:core";
//import "dart:io";
//import "package:logging/logging.dart";
import 'package:http/http.dart' as http;




void main(){
  
//  Uri url = new Uri.http("isapps:Metservice@localhost:8090", "/browseDirectories", {"path":"\log\fastdmo.localhost.log"});
//  print( "${url}");
  
  String url = "http://isapps:Metservice@localhost:8090/downloadFile?path=log/fastdmo.localhost.log";
  http.get( url).then( (response) {
    print( response.body);
  });

  
}
