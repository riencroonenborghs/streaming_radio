import "package:flutter/material.dart";
import "dart:convert";
import 'package:audioplayer/audioplayer.dart';

import "package:StreamingRadio/models/models.dart";

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Streaming Radio",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(title: "Streaming Radio"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}



enum PlayerState { stopped, playing, paused }

class _MyHomePageState extends State<MyHomePage> {
  List<Country> _countries;
  Country _selectedCountry;
  Station _selectedStation;
  AudioPlayer audioPlayer;
  PlayerState playerState;

  Future<Map<String, dynamic>> parseJsonFromAssets(String assetsPath) async {
    return DefaultAssetBundle.of(context).loadString(assetsPath).then((jsonStr) => jsonDecode(jsonStr));
  }
  Widget leftAlign(Widget child) {
    return Align(
      alignment: Alignment.centerLeft,
      child: child
    );
  }

  @override
  void initState() {
    audioPlayer = new AudioPlayer();

    _countries = new List<Country>();
    _countries.add(new Country("be", "België"));
    _countries.add(new Country("nl", "Nederland"));
    _countries.add(new Country("nz", "New Zealand"));

    parseJsonFromAssets("assets/data/stations.json").then((Map<String, dynamic> result) {
      _countries.forEach((country) {
        result[country.code].forEach((stationData) {
          country.addStation(
            new Station(
              stationData["name"],
              stationData["image"],
              stationData["site_url"],
              stationData["radio_url"],
              stationData["description"]
            )
          );
        });
        country.stations.sort((a, b) => a.name.compareTo(b.name));
      });
    });
  }

  @override
  void dispose() {
    if(audioPlayer != null) { audioPlayer.stop(); }
    super.dispose();
  }

  Widget _starredStationsList() {

  }

  Widget _countriesList() {
    return DropdownButton<Country>(
      value: _selectedCountry,
      onChanged: (Country country) {
        _selectCountry(country);
      },
      hint: Text("Select country"),
      items: _countries.map<DropdownMenuItem<Country>>((Country country) {
        return DropdownMenuItem<Country>(
          value: country,
          child: Text(country.name),
        );
      }).toList(),
    );
  }
  _selectCountry(Country country) {
    setState(() {
      _selectedCountry = country;
      _selectedStation = null;
    });
  }

  Widget _stationsList() {
    if(_selectedCountry == null) { return Container(); }

    return DropdownButton<Station>(
      value: _selectedStation,
      onChanged: (Station station) {
        _selectStation(station);
      },
      hint: Text("Select station"),
      items: _selectedCountry.stations.map<DropdownMenuItem<Station>>((Station station) {
        return DropdownMenuItem<Station>(
          value: station,
          child: Text(station.name),
        );
      }).toList(),
    );
  }
  _selectStation(Station station) {
    setState(() {
      _selectedStation = station;
    });
  }
  
  Widget _station() {
    if(_selectedStation == null) { return Container(); }

    Widget title = Padding(
      padding: EdgeInsets.only(bottom: 16.0),
      child: Text(
        _selectedStation.name,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24.0
        )
      )
    );
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            title,
            leftAlign(Text(_selectedStation.description)2),
            _player()
          ]
        )
      )
    );
  }
  Widget _player() {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: isPlaying ? null : () => play(),
                iconSize: 64.0,
                icon: Icon(Icons.play_arrow),
                color: Colors.blue
              ),
              IconButton(
                onPressed: isPlaying ? () => pause() : null,
                iconSize: 64.0,
                icon: Icon(Icons.pause),
                color: Colors.blue
              ),
              IconButton(
                onPressed: isPlaying || isPaused ? () => stop() : null,
                iconSize: 64.0,
                icon: Icon(Icons.stop),
                color: Colors.blue
              )
            ]
          )        
        ]
      )
    );
  }
  get isPlaying => playerState == PlayerState.playing;
  get isPaused => playerState == PlayerState.paused;
  Future play() async {
    await audioPlayer.play(_selectedStation.radioUrl);
    setState(() => playerState = PlayerState.playing);
  }
  Future pause() async {
    await audioPlayer.pause();
    setState(() => playerState = PlayerState.paused);
  }
  Future stop() async {
    await audioPlayer.stop();
    setState(() => playerState = PlayerState.stopped);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title)
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            // _starredStationsList(),
            leftAlign(_countriesList()),
            leftAlign(_stationsList()),
            _station(),
          ]
        )
      )
      // body: Center(
      //   child: Column(
      //     // Column is also layout widget. It takes a list of children and
      //     // arranges them vertically. By default, it sizes itself to fit its
      //     // children horizontally, and tries to be as tall as its parent.
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     children: <Widget>[
      //       Text(
      //         "You have pushed the button this many times:",
      //       ),
      //       Text(
      //         "$_counter",
      //         style: Theme.of(context).textTheme.display1,
      //       ),
      //     ],
      //   ),
      // ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: "Increment",
      //   child: Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
