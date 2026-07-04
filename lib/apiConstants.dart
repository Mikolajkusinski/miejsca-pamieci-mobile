class ApiConstants {
  static const String baseUrl = 'http://localhost:8000/memo_places/';

  static String typesEndpoint = '${baseUrl}types/';
  static String sortofEndpoint = '${baseUrl}sortofs/';
  static String periodEndpoint = '${baseUrl}periods/';
  static String outsideUsersEndpoint = '${baseUrl}outside_users/';
  static String contactUsEndpoint = '${baseUrl}contact_us/';
  static String placesEndpoint = '${baseUrl}places/';
  static String placeImageEndpoint = '${baseUrl}place_image/';
  static String trailsEndpoint = '${baseUrl}path/';
  static String trailImageEndpoint = '${baseUrl}path_image/';
  static String tokenEndpoint = '${baseUrl}token/';
  static String usersEndpoint = '${baseUrl}users/';

  static String displayImageEndpoint(String imgPath) {
    return 'http://localhost:8000$imgPath';
  }

  static String placeImagesByIdEndpoint(String placeId) {
    return '${baseUrl}place_image/place=$placeId';
  }

  static String trailImageByIdEndpoint(String trailId) {
    return '${baseUrl}path_image/path=$trailId';
  }

  static String trailByIdEndpoint(String trailId) {
    return '${baseUrl}path/$trailId/';
  }

  static String trailByPkEndpoint(String trailId) {
    return '${baseUrl}path/pk=$trailId/';
  }

  static String shortTrailsByUserEndpoint(String userId) {
    return '${baseUrl}short_path/user=$userId';
  }

  static String placeByIdEndpoint(String placeId) {
    return '${baseUrl}places/$placeId/';
  }

  static String placeByPkEndpoint(String placeId) {
    return '${baseUrl}places/pk=$placeId/';
  }

  static String shortPlacesByUserEndpoint(String userId) {
    return '${baseUrl}short_places/user=$userId';
  }

  static String userByEmailEndpoint(String email) {
    return '${baseUrl}users/email%3D${email.replaceAll(RegExp(r'\.'), '&')}/';
  }

  static String userByIdEndpoint(int userId) {
    return '${baseUrl}users/$userId/';
  }

  static String resetPasswordByEmailEndpoint(String email) {
    return '${baseUrl}reset_password/email=${email.replaceAll(RegExp(r'\.'), '&')}/';
  }

  static String googleSearchByLatLng(double lat, double lng) {
    return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
  }
}
