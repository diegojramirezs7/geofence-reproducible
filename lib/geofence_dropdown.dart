import 'package:app_reproduce/geofencing_client.dart';
import 'package:app_reproduce/platform_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:app_reproduce/geofence_model.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';

class GeofenceDropdown extends StatefulWidget {
  @override
  _GeofenceDropdownState createState() => _GeofenceDropdownState();
}

class _GeofenceDropdownState extends State<GeofenceDropdown> {
  List<Geofence> availableGeofences = [];
  Geofence dropdownValue = Geofence(name: "Select a Geofence");
  String explanation = "This app needs access to your background location. "
      "For this app to work properly, go to your phone settings and allow the app "
      "to access your location in the background";
  String currentServer = "https://safe-falls-49683.herokuapp.com";
  String hostResult = "";
  List<String> registeredGeofences = [];
  String fileData = "";

  @override
  void initState() {
    getGeofences();

    sendfileDataToServer();

    initializeHost();

    super.initState();
  }

  void sendfileDataToServer() async {
    final result = await GeofencingClient.sendFileData();
    print(result);
  }

  void initializeHost() async {
    try {
      Location location = Location();

      var status = await location.hasPermission();
      if (status != PermissionStatus.granted) {
        var _serviceEnabled = await location.requestPermission();
        if (_serviceEnabled == PermissionStatus.granted) {
          final result = await GeofencingClient.initializeHost("test user", "");
          print(result);
        } else {
          await PlatformAlertDialog(
            title: "Background Location Information",
            content: explanation,
            defaultActionText: "Ok",
          ).show(context);
        }
      } else {
        final result = await GeofencingClient.initializeHost("test user", "");
        print(result);
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> getGeofences() async {
    try {
      String url = '$currentServer/geofences/';
      final response = await http.get(url);

      List<Geofence> geofences = geofencesFromRawJson(response.body);

      setState(() {
        availableGeofences = geofences;
        dropdownValue = availableGeofences.first;
      });
    } catch (e) {
      print(e.toString());
    }
  }

  void registerGeofence() async {
    Location location = Location();

    var status = await location.hasPermission();
    if (status != PermissionStatus.granted) {
      var _serviceEnabled = await location.requestPermission();
      if (_serviceEnabled == PermissionStatus.granted) {
        final result = await GeofencingClient.registerGeofence(dropdownValue);
        setState(() {
          hostResult = result == 'true'
              ? "Successfully added geofence"
              : "Couldn't add geofence";
        });
        print(result);
      } else {
        await PlatformAlertDialog(
          title: "Background Location Information",
          content: explanation,
          defaultActionText: "Ok",
        ).show(context);
      }
    } else {
      final result = await GeofencingClient.registerGeofence(dropdownValue);
      setState(() {
        hostResult = result == 'true'
            ? "Successfully added geofence"
            : "Couldn't add geofence";
      });
      print(result);
    }
  }

  Future<void> testHTTP() async {
    String result = await GeofencingClient.testRequest();
    print(result);
  }

  void fromIdsToNames(List<String> ids) {
    int current;
    List<String> registeredNames = [];
    for (String id in ids) {
      current = int.parse(id);
      String res = availableGeofences
          .firstWhere((element) => element.id == current)
          .name;
      registeredNames.add(res);
    }
    setState(() {
      this.registeredGeofences = registeredNames;
    });
  }

  Future<void> getRegisteredGeofences() async {
    String result = await GeofencingClient.getAllGeofences();
    if (result == "") {
      setState(() {
        this.registeredGeofences = [];
      });
    } else {
      List<String> registeredGeofenceIds = result.trim().split(" ");
      fromIdsToNames(registeredGeofenceIds);
    }
  }

  Future<void> removeGeofenceById() async {
    String result = await GeofencingClient.removeGeofenceById(dropdownValue);
    setState(() {
      hostResult = result == 'true'
          ? "Successfully unregistered from Geofence"
          : "Couldn't unregister geofence";
    });
    print(result);
  }

  void unRegisterGeofence() async {
    Location location = new Location();

    var status = await location.hasPermission();
    if (status != PermissionStatus.granted) {
      var _serviceEnabled = await location.requestPermission();
      if (_serviceEnabled == PermissionStatus.granted) {
        removeGeofenceById();
      } else {
        await PlatformAlertDialog(
          title: "Background Location Information",
          content: explanation,
          defaultActionText: "Ok",
        ).show(context);
      }
    } else {
      removeGeofenceById();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Dropdown list
          Container(
            padding: const EdgeInsets.all(10),
            child: DropdownButton<Geofence>(
              value: dropdownValue,
              icon: Icon(Icons.arrow_downward),
              iconSize: 24,
              elevation: 16,
              style: TextStyle(color: Colors.white),
              underline: Container(
                height: 2,
                color: Color(0xff3E3E3E),
              ),
              onChanged: (Geofence newValue) {
                setState(() {
                  dropdownValue = newValue;
                });
              },
              items: availableGeofences
                  .map<DropdownMenuItem<Geofence>>((Geofence value) {
                return DropdownMenuItem<Geofence>(
                  value: value,
                  child: Text(
                    value.name,
                    style: TextStyle(
                      color: Color(0xff3E3E3E),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // unregister register buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                child: RaisedButton(
                    child: const Text('Unregister',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    //color: Color(0xff3E3E3E),
                    color: Colors.red.shade600,
                    onPressed: () {
                      //unRegisterGeofence();
                      unRegisterGeofence();
                    }),
                padding: const EdgeInsets.only(right: 16),
              ),
              RaisedButton(
                  child: const Text(
                    'Register',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  color: Colors.green.shade600,
                  onPressed: () async {
                    registerGeofence();
                  }),
            ],
          ),
          //Privacy button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                color: Color(0xff3E3E3E),
                margin: const EdgeInsets.all(8),
                child: TextButton(
                    onPressed: () async {
                      //_launchURL();
                      final res = await GeofencingClient.test();
                      print(res);
                    },
                    child: Text(
                      "send test event",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    )),
              ),
              Container(
                color: Color(0xff3E3E3E),
                margin: const EdgeInsets.all(8),
                child: TextButton(
                    onPressed: () {
                      getRegisteredGeofences();
                    },
                    child: Text(
                      "Get active Geofences",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    )),
              ),
            ],
          ),
          Container(
            color: Color(0xff3E3E3E),
            margin: const EdgeInsets.all(16),
            child: TextButton(
                onPressed: () async {
                  //_launchURL();
                  final res = await GeofencingClient.randomTest();
                  setState(() {
                    fileData = res;
                  });
                },
                child: Text(
                  "Get contents from log file",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                )),
          ),
          //result text
          Container(
            child: Text(hostResult),
          ),
          // get geofences button

          // list of geofences
          Expanded(
            //height: 170,
            child: ListView(
              children: registeredGeofences
                  .map(
                    (e) => Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: Color(0xff3E3E3E),
                      ),
                      child: Text(
                        e,
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
              child: SingleChildScrollView(
            child: Text(fileData),
          ))
        ],
      ),
    );
  }
}
