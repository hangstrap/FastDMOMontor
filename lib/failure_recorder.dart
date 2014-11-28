library failure_recorder;

import 'server.dart';
import "dart:io";
import 'package:jsonx/jsonx.dart' as jsonx;
import 'package:path/path.dart' as path;

class FailureRecorder{
  
  File jsonFile; 
  List<FaultRecord> failures =[];
  
  FailureRecorder( Directory directory){
    
    _createOutputFile(directory);

  }


  void hadFailure( Server server, String status, File logFile, File htmlFile, {DateTime when:null}){
    
    FaultRecord fr = new FaultRecord.create(server, status, logFile, htmlFile);
    if( when != null){
      fr.when = when;
    }
    failures.add( fr);
    _updateOutputFile();
  }

  void _createOutputFile(Directory directory) {
    jsonFile = new File( path.join(directory.path,"failure_record.json"));
    if( !jsonFile.existsSync()){
      jsonFile.createSync() ;
      _updateOutputFile();
    }
    _loadFromOutputFile();
    
  }
  void _updateOutputFile(){
    jsonFile.writeAsStringSync( jsonx.encode( failures));
  }
  void _loadFromOutputFile(){
    String json = jsonFile.readAsStringSync( );
    failures= jsonx.decode( json, type: const jsonx.TypeHelper<List<FaultRecord>>().type);
  }
}

class FaultRecord{
  
  String serverName;
  String status;
  String logFile;
  String htmlFile;
  DateTime when;
  
  FaultRecord();
  
  FaultRecord.create( Server server, this.status, File logFile, File htmlFile): this.when = new DateTime.now().toUtc(){
    serverName = server.name;
    this.logFile = path.basename(logFile.path);
    this.htmlFile = path.basename(htmlFile.path);
  }
  
}