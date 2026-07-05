/// Only absolute http(s) URLs with a host may be saved or launched — this
/// blocks `javascript:`, `tel:`, `file:` etc. arriving from user input or
/// server data. Returns the parsed [Uri], or null when the link is unsafe.
Uri? parseSafeHttpUrl(String link) {
  final uri = Uri.tryParse(link.trim());
  if (uri == null || uri.host.isEmpty) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  return uri;
}
