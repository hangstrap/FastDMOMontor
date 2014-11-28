import 'package:unittest/unittest.dart';
import 'package:FastDMOMontor/failure_recorder.dart';
import 'package:FastDMOMontor/server.dart';
import 'package:path/path.dart' as path;
import 'package:jsonx/jsonx.dart' as jsonx;
import "dart:io";
import 'dart:async';


String jsonAlertMessage = '{"serverName":"test","status":"P1 4","logFile":"test.log","htmlFile":"test.html","when":"2014-11-28 02:29:33.228Z"}';
String jsonAlertMessageList = '[${jsonAlertMessage}]';

void main() {

  Server server = new Server("test", "http://test");
  File logFile = new File("dir/test.log");
  File htmlFile = new File("dir/test.html");

  DateTime now = DateTime.parse("2014-11-28 02:29:33.228Z");

  group("failure_recorder", () {

    FailureRecorder underTest;
    Directory outputDirectory;
    File outputFile;


    setUp(() {

      outputDirectory = Directory.systemTemp.createTempSync("failure_recorder_test");
      outputFile = new File(path.join(outputDirectory.path, "failure_record.json"));

      underTest = new FailureRecorder(outputDirectory);

    });
    test('empty on startup', () {

      expect(underTest.failures.length, equals(0));

    });
    test('Should create a json file', () {

      List<FileSystemEntity> files = outputDirectory.listSync();
      expect(files.length, equals(1));
      FileSystemEntity createdFile = files[0];

      expect(FileSystemEntity.isFileSync(createdFile.path), equals(true));
      expect(createdFile.path, equals(outputFile.path));
    });
    test('New file should contain a empty json document', () {

      String fileContents = outputFile.readAsStringSync();
      expect(fileContents, equals("[]"));

    });

    group("Adding a fault", () {
      test('should add to internal list', () {


        underTest.hadFailure(server, "P3 1", logFile, htmlFile);
        expect(underTest.failures.length, equals(1));

        FaultRecord fault = underTest.failures[0];
        expect(fault.serverName, equals(server.name));
        expect(fault.status, equals("P3 1"));
        expect(fault.logFile, equals("test.log"));
        expect(fault.htmlFile, equals("test.html"));
      });

      test('should write any faultRecord  that occure to file on disk', () {

        underTest.hadFailure(server, "P1 4", logFile, htmlFile, when: now);


        String fileContents = outputFile.readAsStringSync();
        expect(fileContents, equals(jsonAlertMessageList));


      });
    });

    solo_test("should load old records from file on startup", () {

      outputFile.writeAsStringSync(jsonAlertMessageList);
      underTest = new FailureRecorder(outputDirectory);

      expect(underTest.failures.length, equals(1));

      FaultRecord fault = underTest.failures[0];
      expect(fault.serverName, equals(server.name));
      expect(fault.status, equals("P1 4"));
      expect(fault.logFile, equals("test.log"));
      expect(fault.htmlFile, equals("test.html"));
      expect(fault.when, equals(now));
    });
  });

  group("json tests of FaultRecord", () {

    test("stream to json", () {
      FaultRecord fr = new FaultRecord.create(server, "P1 4", logFile, htmlFile);
      fr.when = now;

      expect(jsonx.encode(fr), equals(jsonAlertMessage));
    });

    test("stream list to json", () {
      FaultRecord fr = new FaultRecord.create(server, "P1 4", logFile, htmlFile);
      fr.when = now;

      expect(jsonx.encode([fr]), equals(jsonAlertMessageList));
    });

    test("stream json to List", () {

      String json = jsonAlertMessageList;
      var records = jsonx.decode(json, type: const jsonx.TypeHelper<List<FaultRecord>>().type);
      FaultRecord fault = records[0];
      expect(fault.serverName, equals(server.name));
      expect(fault.status, equals("P1 4"));
      expect(fault.logFile, equals("test.log"));
      expect(fault.htmlFile, equals('test.html'));
      expect(fault.when, equals(now));


    });

  });
}
