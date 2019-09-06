import "package:StreamingRadio/models/models.dart";

class Station {
  Country _country;
  String _name;
  String _image;
  String _siteUrl;
  String _radioUrl;
  String _description;
  bool _starred = false;

  Station(
    String name,
    String image,
    String siteUrl,
    String radioUrl,
    String description) {
    this._name = name;
    this._image = image;
    this._siteUrl = siteUrl;
    this._radioUrl = radioUrl;
    this._description = description;
  }

  Country get country => _country;
  String get name => _name;
  String get image => _image;
  String get siteUrl => _siteUrl;
  String get radioUrl => _radioUrl;
  String get description => _description;
  bool get starred => _starred;

  set country(Country country) => this._country = country;

}