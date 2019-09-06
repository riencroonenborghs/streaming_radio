import "package:StreamingRadio/models/models.dart";

class Country {
  String _code;
  String _name;
  List<Station> _stations;

  Country(String code, String name) {
    this._code = code;
    this._name = name;
    this._stations = new List<Station>();
  }

  String get code => _code;
  String get name => _name;
  List<Station> get stations => _stations;

  addStation(Station station) {
    station.country = this;
    this._stations.add(station);
  }
}