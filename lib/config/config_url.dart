import "package:flutter_dotenv/flutter_dotenv.dart";

class Config_URL {
  static String get baseApiUrl {
    final url = dotenv.env['BASE_URL'];
    if (url == null) {
      print("BASE_URL is not set in the .env file. Using default URL.");
      return "https://10.0.2.2:7132/api";
     // return "https://widegreenkayak0.conveyor.cloud/api";
    }
    return url;
  }
  static String get baseUrl {
    final url = dotenv.env['BASE_URL_IMAGE'];
    if (url == null) {
      print("BASE_URL is not set in the .env file. Using default URL.");
      return "https://10.0.2.2:7132";
    //  return "https://widegreenkayak0.conveyor.cloud/";
    }
    return url;
  }
}