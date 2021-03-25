import 'package:app_reproduce/geofence_model.dart';
import 'package:flutter/services.dart';

class GeofencingClient {
  static const platform = const MethodChannel("com.tradespecifix.geofencing");

  static Future<String> initializeHost(String userName, String email) async {
    final String result = await platform.invokeMethod(
        "initializeHost", {"user_name": userName, "email": email});

    return result;
  }

  static Future<String> randomTest() async {
    // now gets data from file
    final String result = await platform.invokeMethod("randomTest");
    return result;
  }

  static Future<String> test() async {
    final String result = await platform.invokeMethod("test");
    return result;
  }

  static Future<String> registerGeofence(Geofence geofence) async {
    final String result = await platform.invokeMethod('registerGeofence', {
      'name': geofence.id.toString(),
      'latitude': geofence.lat,
      'longitude': geofence.lng,
      'radius': geofence.radius
    });

    return result;
  }

  static Future<String> testRequest() async {
    final String result = await platform.invokeMethod("testHTTP");

    return result;
  }

  static Future<String> getAllGeofences() async {
    final String result = await platform.invokeMethod("getAllGeofences");
    return result;
  }

  static Future<String> removeAllGeofences() async {
    final String result = await platform.invokeMethod("removeAllGeofences");
    return result;
  }

  static Future<String> removeGeofenceById(Geofence geofence) async {
    String reqId = geofence.id.toString();
    final String result = await platform
        .invokeMethod("removeGeofenceById", {"identifier": reqId});

    return result;
  }

  static Future<String> sendFileData() async {
    final String result = await platform.invokeMethod("sendFileData");
    return result;
  }
}
