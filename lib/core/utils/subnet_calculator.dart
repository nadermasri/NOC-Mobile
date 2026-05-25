class SubnetCalculator {
  final String cidr;
  late final int _ip;
  late final int _prefix;
  late final int _mask;

  SubnetCalculator(this.cidr) {
    final parts = cidr.split('/');
    if (parts.length != 2) {
      throw FormatException('Invalid CIDR notation: $cidr');
    }

    _ip = _parseIp(parts[0]);
    _prefix = int.parse(parts[1]);

    if (_prefix < 0 || _prefix > 32) {
      throw FormatException('Invalid prefix length: $_prefix');
    }

    _mask = _prefix == 0 ? 0 : (~0 << (32 - _prefix)) & 0xFFFFFFFF;
  }

  static int _parseIp(String ip) {
    final octets = ip.split('.');
    if (octets.length != 4) {
      throw FormatException('Invalid IP address: $ip');
    }

    int result = 0;
    for (final octet in octets) {
      final val = int.parse(octet);
      if (val < 0 || val > 255) {
        throw FormatException('Invalid octet: $octet');
      }
      result = (result << 8) | val;
    }
    return result;
  }

  static String _formatIp(int ip) {
    return '${(ip >> 24) & 0xFF}.${(ip >> 16) & 0xFF}.${(ip >> 8) & 0xFF}.${ip & 0xFF}';
  }

  String get networkAddress => _formatIp(_ip & _mask);

  String get broadcastAddress {
    final wildcard = ~_mask & 0xFFFFFFFF;
    return _formatIp((_ip & _mask) | wildcard);
  }

  String get subnetMask => _formatIp(_mask);

  String get wildcardMask => _formatIp(~_mask & 0xFFFFFFFF);

  int get totalHosts {
    if (_prefix >= 31) return _prefix == 32 ? 1 : 2;
    return (1 << (32 - _prefix));
  }

  int get usableHosts {
    if (_prefix >= 31) return _prefix == 32 ? 1 : 2;
    return totalHosts - 2;
  }

  String get firstUsableHost {
    if (_prefix >= 31) return networkAddress;
    return _formatIp((_ip & _mask) + 1);
  }

  String get lastUsableHost {
    if (_prefix >= 31) return broadcastAddress;
    final wildcard = ~_mask & 0xFFFFFFFF;
    return _formatIp((_ip & _mask) | (wildcard - 1));
  }

  String get usableRange => '$firstUsableHost - $lastUsableHost';

  String get ipClass {
    final firstOctet = (_ip >> 24) & 0xFF;
    if (firstOctet < 128) return 'A';
    if (firstOctet < 192) return 'B';
    if (firstOctet < 224) return 'C';
    if (firstOctet < 240) return 'D';
    return 'E';
  }

  bool get isPrivate {
    final firstOctet = (_ip >> 24) & 0xFF;
    final secondOctet = (_ip >> 16) & 0xFF;

    if (firstOctet == 10) return true;
    if (firstOctet == 172 && secondOctet >= 16 && secondOctet <= 31) return true;
    if (firstOctet == 192 && secondOctet == 168) return true;
    return false;
  }

  String get binaryMask {
    final sb = StringBuffer();
    for (int i = 31; i >= 0; i--) {
      sb.write((_mask >> i) & 1);
      if (i % 8 == 0 && i > 0) sb.write('.');
    }
    return sb.toString();
  }

  Map<String, dynamic> calculate() {
    return {
      'cidr': cidr,
      'networkAddress': networkAddress,
      'broadcastAddress': broadcastAddress,
      'subnetMask': subnetMask,
      'wildcardMask': wildcardMask,
      'totalHosts': totalHosts,
      'usableHosts': usableHosts,
      'firstUsableHost': firstUsableHost,
      'lastUsableHost': lastUsableHost,
      'usableRange': usableRange,
      'prefix': _prefix,
      'ipClass': ipClass,
      'isPrivate': isPrivate,
      'binaryMask': binaryMask,
    };
  }
}
