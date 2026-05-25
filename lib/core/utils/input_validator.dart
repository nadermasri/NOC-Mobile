class InputValidator {
  InputValidator._();

  static final _hostnameRegex = RegExp(
    r'^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$',
  );

  static final _ipv4Regex = RegExp(
    r'^((25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(25[0-5]|2[0-4]\d|[01]?\d\d?)$',
  );

  static final _ipv6Regex = RegExp(
    r'^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$|^::$|^([0-9a-fA-F]{1,4}:)*:[0-9a-fA-F:]*$',
  );

  static final _cidrRegex = RegExp(
    r'^((25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(25[0-5]|2[0-4]\d|[01]?\d\d?)\/(3[0-2]|[12]?\d)$',
  );

  static bool isValidHostname(String value) {
    if (value.isEmpty || value.length > 253) return false;
    return _hostnameRegex.hasMatch(value);
  }

  static bool isValidIpv4(String value) {
    return _ipv4Regex.hasMatch(value);
  }

  static bool isValidIpv6(String value) {
    return _ipv6Regex.hasMatch(value);
  }

  static bool isValidHost(String value) {
    final trimmed = value.trim();
    return isValidHostname(trimmed) ||
        isValidIpv4(trimmed) ||
        isValidIpv6(trimmed);
  }

  static bool isValidPort(String value) {
    final port = int.tryParse(value);
    return port != null && port >= 1 && port <= 65535;
  }

  static bool isValidCidr(String value) {
    return _cidrRegex.hasMatch(value.trim());
  }

  static bool isValidUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.length > 2048) return false;

    try {
      final uri = Uri.parse(
        trimmed.startsWith('http') ? trimmed : 'https://$trimmed',
      );
      return uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static String sanitizeHost(String value) {
    return value.trim().replaceAll(RegExp(r'[^\w.\-:]'), '');
  }

  static String sanitizeUrl(String value) {
    var trimmed = value.trim();
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'https://$trimmed';
    }
    return trimmed;
  }

  static String? validateHostField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a hostname or IP address';
    }
    if (!isValidHost(value.trim())) {
      return 'Invalid hostname or IP address';
    }
    return null;
  }

  static String? validatePortField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a port number';
    }
    if (!isValidPort(value.trim())) {
      return 'Invalid port (1-65535)';
    }
    return null;
  }

  static String? validateUrlField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a URL';
    }
    if (!isValidUrl(value.trim())) {
      return 'Invalid URL';
    }
    return null;
  }

  static String? validateCidrField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter CIDR notation';
    }
    if (!isValidCidr(value.trim())) {
      return 'Invalid CIDR (e.g. 192.168.1.0/24)';
    }
    return null;
  }
}
