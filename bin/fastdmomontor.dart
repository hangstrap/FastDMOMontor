import "dart:async";
import "dart:core";
import "dart:io";
import 'dart:convert' show UTF8, JSON;

class Server {
  String name;
  String url;
  Server(this.name, this.url);
}

Future<String>  getStatus(Server server) {
  
  Uri url = new Uri.http(server.url, "health");
  print( "getting status from ${server.name}");
  
  return new HttpClient().getUrl(url).then((HttpClientRequest request) {
    return request.close();
  }).then((HttpClientResponse response) {
    response.transform(UTF8.decoder).listen((contents) {
      
      print( "${server.name} returned a status of ${contents}");
      return contents;
    });
  });

}



void main() {
  List<Server> servers = [new Server("prod.ec", "isapps:M3ts3rv1c3@fastdmo-ec.amazon.metcloudservices.com:8080"), 
                          new Server("prod.gfs", "isapps:M3ts3rv1c3@fastdmo-gfs.amazon.metcloudservices.com:8080"), 
                          new Server("preprod.ec", "isapps:M3ts3rv1c3@fastdmo-gfs.amazon-preprod.metcloudservices.com:8080"), 
                          new Server("preprod.gfs", "isapps:M3ts3rv1c3@fastdmo-gfs.amazon-preprod.metcloudservices.com:8080")];


  servers.forEach((server) {
    getStatus(server).then( (result)=> print( "${server.name} ${result}"));

  });



}
