import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:full_map_use/Model/Time_Distance_Model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Map_Screen extends StatefulWidget {
  @override
  _Map_ScreenState createState() => _Map_ScreenState();
}

class _Map_ScreenState extends State<Map_Screen> {
  GoogleMapController mapController;
  double _originLatitude = 21.1959, _originLongitude = 72.7933;
  double _destLatitude = 21.1418, _destLongitude = 72.7709;

  Map<MarkerId, Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  String googleAPiKey = "AIzaSyCZa1NSFDU4eVIbBxW_XA3KSET8-ejecsk";
  bool showData = false;
  MapData mapData;
  String _mode = 'Choose Mode';

  @override
  void initState() {
    super.initState();
    _addMarker(LatLng(_originLatitude, _originLongitude), "origin",
        BitmapDescriptor.defaultMarker);

    _addMarker(LatLng(_destLatitude, _destLongitude), "destination",
        BitmapDescriptor.defaultMarkerWithHue(90));
    _getPolyline();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            "Travel Time And Distance",
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.blue[900],
        ),
        body: mainLayout(),
      ),
    );
  }

  Widget mainLayout() {
    return Column(
      children: <Widget>[
        Container(
          height: MediaQuery.of(context).size.height * 0.78,
          child: Stack(
            children: <Widget>[
              googleMap(),
              timeAndDistance(),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            selectTypeOfTravel(),
            goButton(),
          ],
        )
      ],
    );
  }

  Widget timeAndDistance() {
    return Container(
      alignment: Alignment.center,
      color: Colors.white,
      height: MediaQuery.of(context).size.height * 0.1,
      width: double.maxFinite,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(showData
              ? "Travel Time: ${mapData.rows[0].elements[0].duration.text}"
              : 'Travel Time: 0 mins'),
          Text(showData
              ? "Travel Distance: ${mapData.rows[0].elements[0].distance.text}"
              : 'Travel Distance: 0 Km')
        ],
      ),
    );
  }

  Widget selectTypeOfTravel() {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: DropdownButton<String>(
        value: _mode,
        icon: Icon(
          Icons.arrow_downward,
          color: Colors.blue[900],
        ),
        iconSize: 24,
        elevation: 16,
        style: TextStyle(color: Colors.blue[900]),
        underline: Container(
          height: 2,
          color: Colors.blue[900],
        ),
        onChanged: (String newValue) {
          setState(() {
            _mode = newValue;
          });
        },
        items: <String>[
          'Choose Mode',
          'driving',
          'walking',
          'bicycling',
          'transit'
        ].map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }

  Widget goButton() {
    return InkWell(
      onTap: getTimeAndDuration,
      child: Container(
        height: 35,
        width: 80,
        decoration: BoxDecoration(
            color: Colors.blue[900],
            borderRadius: BorderRadius.all(Radius.circular(50))),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 8,
            ),
            Icon(
              Icons.forward,
              color: Colors.white,
              size: 30,
            ),
            SizedBox(
              width: 8,
            ),
            Text(
              'Go',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(
              width: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget googleMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
          target: LatLng(_originLatitude, _originLongitude), zoom: 15),
      onMapCreated: _onMapCreated,
      markers: Set<Marker>.of(markers.values),
      polylines: Set<Polyline>.of(polylines.values),
    );
  }

  void _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
  }

  _addMarker(LatLng position, String id, BitmapDescriptor descriptor) {
    MarkerId markerId = MarkerId(id);
    Marker marker =
        Marker(markerId: markerId, icon: descriptor, position: position);
    markers[markerId] = marker;
  }

  _addPolyLine() {
    PolylineId id = PolylineId("Current Polyline");
    Polyline polyline = Polyline(
        polylineId: id,
        color: Colors.red,
        points: polylineCoordinates,
        width: 3);
    polylines[id] = polyline;
    setState(() {});
  }

  _getPolyline() async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleAPiKey,
      PointLatLng(_originLatitude, _originLongitude),
      PointLatLng(_destLatitude, _destLongitude),
      travelMode: TravelMode.driving,
    );
    if (result.points.isNotEmpty) {
      result.points.forEach(
        (PointLatLng point) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        },
      );
    }
    _addPolyLine();
  }

  getTimeAndDuration() async {
    try {
      http.Response response = await http.get(
        'https://maps.googleapis.com/maps/api/distancematrix/json?'
        'origins=$_originLatitude,$_originLongitude'
        '&destinations=$_destLatitude,$_destLongitude'
        '&key=$googleAPiKey'
        '&mode=$_mode',
      );
      var body = json.decode(response.body);
      mapData = MapData.fromJson(body);
      if (_mode != "Choose Mode") {
        if (mapData.rows[0].elements[0].status.toString() == "OK" &&
            mapData.status.toString() == "OK") {
          setState(() {
            showData = true;
          });
        } else {
          noAvailbleAlert(context);
        }
      } else {
        noChooseAlert(context);
      }

      return mapData;
    } catch (error) {
      print(error);
    }
  }

  Future<void> noAvailbleAlert(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$_mode Mode Travel Time and Distance is Not Availble'),
          titleTextStyle: TextStyle(fontSize: 18, color: Colors.black),
          actions: <Widget>[
            FlatButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  showData = false;
                });
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> noChooseAlert(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Please First Travel Mode Choose!!'),
          titleTextStyle: TextStyle(fontSize: 18, color: Colors.black),
          actions: <Widget>[
            FlatButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  showData = false;
                });
              },
            ),
          ],
        );
      },
    );
  }
}
