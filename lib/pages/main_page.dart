import "package:flutter/material.dart";
import "package:audioplayer/audioplayer.dart";
import "package:url_launcher/url_launcher.dart";
import "dart:convert";
import "dart:async";

import "package:StreamingRadio/models/models.dart";
import "package:StreamingRadio/widgets/widgets.dart";
import "package:StreamingRadio/services/services.dart";

enum PlayerState { stopped, playing, paused }

class MainPage extends StatefulWidget {
  MainPage({Key key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  AudioPlayer _audioPlayer = new AudioPlayer();
  List<Country> _countries = new List<Country>();
  DatabaseService _databaseService = new DatabaseService();
  Country _selectedCountry;
  Station _selectedStation;
  Station _selectedStarredStation;
  List<Station> _starredStations = new List<Station>();
  List<String> _starredStationsFromDatabase;
  PlayerState _playerState;
  num _secondsPlaying = 0;
  Timer _timer;

  Future<Map<String, dynamic>> _parseJsonFromAssets(String assetsPath) async {
    return DefaultAssetBundle.of(context).loadString(assetsPath).then((jsonStr) => jsonDecode(jsonStr));
  }

  Widget _leftAlign(Widget child) {
    return Align(
      alignment: Alignment.centerLeft,
      child: child
    );
  }

  _launchURL(String url) async {
    if(await canLaunch(url)) {
      await launch(url);
    } else {
      throw "Could not launch ${url}";
    }
  }

  @override
  void initState() {
    _loadStarredStationsCountriesAndStations();   
  }

  _loadStarredStationsCountriesAndStations() {
    _countries = new List<Country>();
    _starredStations = new List<Station>();

    _databaseService.getStarredStations().then((data) {
      _starredStationsFromDatabase = data;
      _loadCountriesAndStations();
    }); 
  }

  _loadCountriesAndStations() {
    _parseJsonFromAssets("assets/data/countries.json").then((Map<String, dynamic> countriesData) {
      // create all the countries
      countriesData.forEach((code, name) {
        _countries.add(new Country(code, name));
      });
      _countries.sort((a, b) => a.name.compareTo(b.name));
      _loadStations();
    });
  }

  _loadStations() {
    _parseJsonFromAssets("assets/data/stations.json").then((Map<String, dynamic> stationsData) {
      // create all the stations per country
      _countries.forEach((country) {
        stationsData[country.code].forEach((stationData) {
          Station station = new Station(
            stationData["name"],
            stationData["image"],
            stationData["site_url"],
            stationData["radio_url"],
            stationData["description"]
          );
          country.addStation(station);
          // check if station is in our database list of starred stations
          bool isStarred = _starredStationsFromDatabase.firstWhere(
            (radioUrl) => radioUrl == station.radioUrl,
            orElse: () => null
          ) != null;
          // if it is, add it to the list of starred stations
          if(isStarred) { _starredStations.add(station); }
        });
        country.stations.sort((a, b) => a.name.compareTo(b.name));        
      });
      _sortStarredStations();

      // just to repaint the screen after loading the assets
      setState(() { _stop(); });
    });
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    super.dispose();
  }

  // ----------
  // starred stations
  // ----------

  _sortStarredStations() {
    _starredStations.sort((a, b) => a.fullName().compareTo(b.fullName()));
  }

  _isStarredStation() {
    return _starredStations.firstWhere(
      (starredStation) => starredStation.radioUrl == _selectedStation.radioUrl,
      orElse: () => null
    ) != null;
  }

  Widget _starredStationsList() {
    if(_starredStations.isEmpty) { return Container(); }

    return DropdownButton<Station>(
      isExpanded: true,
      value: _selectedStarredStation,
      onChanged: (Station station) {
        _selectStarredStation(station);
      },
      hint: Text("Select remembered station"),
      items: _starredStations.map<DropdownMenuItem<Station>>((Station station) {
        return DropdownMenuItem<Station>(
          value: station,
          child: Text(station.fullName())
        );
      }).toList(),
    );
  }

  _selectStarredStation(Station station) {
    setState(() {
      _stop();
      _selectedStarredStation = station;
      _selectedCountry = station.country;
      _selectedStation = station;
    });
  }

  // ----------
  // countries
  // ----------
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
      _stop();
      _selectedCountry = country;
      _selectedStation = null;
    });
  }

  // ----------
  // stations
  // ----------
  Widget _stationsList() {
    if(_selectedCountry == null) { return Container(); }

    return DropdownButton<Station>(
      isExpanded: true,
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
      _stop();
      _selectedStation = station;
    });
  }

  _rememberStation() async {
    bool result = await _databaseService.saveStarredStation(_selectedStation);
    if(result) {
      setState(() {
        _selectedStarredStation = _selectedStation;
        _starredStations.add(_selectedStation);
        _sortStarredStations();
      });
    }
  }
  _forgetStation() async {
    bool result = await _databaseService.removeStarredStation(_selectedStation);
    if(result) {
      setState(() { 
        _selectedStarredStation = null;
        _starredStations.remove(_selectedStation);
       _sortStarredStations();
      });
    }
  }
  
  Widget _station() {
    if(_selectedStation == null) { return Container(); }

    Widget title = Text(
      _selectedStation.name,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 24.0
      )
    );

    Widget avatar = Padding(
      padding: EdgeInsets.only(right: 16.0),
      child: GestureDetector(
        onTap: () {
          _launchURL(_selectedStation.siteUrl);
        },
        child: Avatar(name: _selectedStation.name)
      )
    );

    bool stationIsStarred = _isStarredStation();

    Widget starring = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        IconButton(
          icon: stationIsStarred ? Icon(Icons.star) : Icon(Icons.star_border),
          onPressed: () {
            if(stationIsStarred) {
              _forgetStation();              
            } else {
              _rememberStation();
            }
          },
        ),
        Text("${stationIsStarred ? 'Forget' : 'Remember'} this station")
      ]
    );

    Widget top = Padding(
      padding: EdgeInsets.only(bottom: 16.0),
      child: Row(        
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          avatar,
          Expanded(
            child: Column(
              children: [
                _leftAlign(title),
                starring
              ]
            )
          )
        ]
      )
    );
    
    return Card(
      elevation: 5,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            top,
            _leftAlign(Text(_selectedStation.description)),
            _player()
          ]
        )
      )
    );
  }

  // ----------
  // player
  // ----------
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
                onPressed: _isPlaying ? null : () => _play(),
                iconSize: 64.0,
                icon: Icon(Icons.play_arrow),
                color: Theme.of(context).primaryColor
              ),
              IconButton(
                onPressed: _isPlaying ? () => _pause() : null,
                iconSize: 64.0,
                icon: Icon(Icons.pause),
                color: Theme.of(context).primaryColor
              ),
              IconButton(
                onPressed: _isPlaying || _isPaused ? () => _stop() : null,
                iconSize: 64.0,
                icon: Icon(Icons.stop),
                color: Theme.of(context).primaryColor
              )
            ]
          ),
          _isPlaying ? _hhmm() : Container()
        ]
      )      
    );
  }

  get _isPlaying => _playerState == PlayerState.playing;
  get _isPaused => _playerState == PlayerState.paused;
  
  Future _play() async {
    await _audioPlayer.play(_selectedStation.radioUrl);
    setState(() => _playerState = PlayerState.playing);
    _startTimer();
  }
  
  Future _pause() async {
    await _audioPlayer.pause();
    setState(() => _playerState = PlayerState.paused);
  }
  
  Future _stop() async {
    await _audioPlayer.stop();
    _secondsPlaying = 0;
    setState(() => _playerState = PlayerState.stopped);
    _stopTimer(true);
  }

  // ----------
  // hhmmss
  // ----------
  Widget _hhmm() {
    num time = _secondsPlaying;
    num hh = (time / 3600).round();
    time -= hh * 3600;
    String hhString = hh > 10 ? "${hh}" : "0${hh}";
    num mm = (time / 60).round();
    time -= mm * 60;
    String mmString = mm > 10 ? "${mm}" : "0${mm}";
    num ss = time % 60;
    String ssString = ss > 10 ? "${ss}" : "0${ss}";
    return Text("${hhString}:${mmString}:${ssString}");
  }

  _startTimer() {
    _stopTimer(false);
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {
        if(_isPlaying) { _secondsPlaying += 1; }
      });      
    });
  }

  _stopTimer(bool reset) {
    if(_timer != null && _timer.isActive) {
      _timer.cancel();
    }
    if(reset) {
      _secondsPlaying = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Streaming Radio")
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            _starredStationsList(),
            _leftAlign(_countriesList()),
            _leftAlign(_stationsList()),
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
