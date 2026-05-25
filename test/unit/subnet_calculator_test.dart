import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_noc/core/utils/subnet_calculator.dart';

void main() {
  group('SubnetCalculator', () {
    test('calculates /24 network correctly', () {
      final calc = SubnetCalculator('192.168.1.0/24');
      expect(calc.networkAddress, '192.168.1.0');
      expect(calc.broadcastAddress, '192.168.1.255');
      expect(calc.subnetMask, '255.255.255.0');
      expect(calc.wildcardMask, '0.0.0.255');
      expect(calc.usableHosts, 254);
      expect(calc.totalHosts, 256);
      expect(calc.firstUsableHost, '192.168.1.1');
      expect(calc.lastUsableHost, '192.168.1.254');
      expect(calc.ipClass, 'C');
      expect(calc.isPrivate, true);
    });

    test('calculates /16 network correctly', () {
      final calc = SubnetCalculator('10.0.0.0/16');
      expect(calc.networkAddress, '10.0.0.0');
      expect(calc.broadcastAddress, '10.0.255.255');
      expect(calc.subnetMask, '255.255.0.0');
      expect(calc.usableHosts, 65534);
      expect(calc.totalHosts, 65536);
      expect(calc.firstUsableHost, '10.0.0.1');
      expect(calc.lastUsableHost, '10.0.255.254');
      expect(calc.ipClass, 'A');
      expect(calc.isPrivate, true);
    });

    test('calculates /32 host route', () {
      final calc = SubnetCalculator('192.168.1.1/32');
      expect(calc.networkAddress, '192.168.1.1');
      expect(calc.broadcastAddress, '192.168.1.1');
      expect(calc.usableHosts, 1);
      expect(calc.totalHosts, 1);
    });

    test('calculates /31 point-to-point', () {
      final calc = SubnetCalculator('10.0.0.0/31');
      expect(calc.networkAddress, '10.0.0.0');
      expect(calc.broadcastAddress, '10.0.0.1');
      expect(calc.usableHosts, 2);
      expect(calc.totalHosts, 2);
    });

    test('calculates /8 network correctly', () {
      final calc = SubnetCalculator('10.0.0.0/8');
      expect(calc.networkAddress, '10.0.0.0');
      expect(calc.broadcastAddress, '10.255.255.255');
      expect(calc.subnetMask, '255.0.0.0');
      expect(calc.usableHosts, 16777214);
    });

    test('handles non-network-aligned address', () {
      final calc = SubnetCalculator('192.168.1.100/24');
      expect(calc.networkAddress, '192.168.1.0');
      expect(calc.broadcastAddress, '192.168.1.255');
      expect(calc.usableHosts, 254);
    });

    test('identifies private ranges', () {
      expect(SubnetCalculator('10.0.0.0/8').isPrivate, true);
      expect(SubnetCalculator('172.16.0.0/12').isPrivate, true);
      expect(SubnetCalculator('172.31.255.0/24').isPrivate, true);
      expect(SubnetCalculator('192.168.0.0/16').isPrivate, true);
      expect(SubnetCalculator('8.8.8.0/24').isPrivate, false);
      expect(SubnetCalculator('1.1.1.0/24').isPrivate, false);
    });

    test('identifies IP classes', () {
      expect(SubnetCalculator('10.0.0.0/8').ipClass, 'A');
      expect(SubnetCalculator('172.16.0.0/12').ipClass, 'B');
      expect(SubnetCalculator('192.168.1.0/24').ipClass, 'C');
      expect(SubnetCalculator('224.0.0.0/4').ipClass, 'D');
      expect(SubnetCalculator('240.0.0.0/4').ipClass, 'E');
    });

    test('generates binary mask', () {
      final calc = SubnetCalculator('192.168.1.0/24');
      expect(calc.binaryMask, '11111111.11111111.11111111.00000000');
    });

    test('generates binary mask for /20', () {
      final calc = SubnetCalculator('10.0.0.0/20');
      expect(calc.binaryMask, '11111111.11111111.11110000.00000000');
    });

    test('throws on invalid CIDR', () {
      expect(() => SubnetCalculator('invalid'), throwsFormatException);
      expect(() => SubnetCalculator('192.168.1.0/33'), throwsFormatException);
      expect(() => SubnetCalculator('256.0.0.0/24'), throwsFormatException);
      expect(() => SubnetCalculator('192.168.1/24'), throwsFormatException);
    });

    test('calculate returns complete map', () {
      final result = SubnetCalculator('192.168.1.0/24').calculate();
      expect(result.containsKey('cidr'), true);
      expect(result.containsKey('networkAddress'), true);
      expect(result.containsKey('broadcastAddress'), true);
      expect(result.containsKey('subnetMask'), true);
      expect(result.containsKey('wildcardMask'), true);
      expect(result.containsKey('totalHosts'), true);
      expect(result.containsKey('usableHosts'), true);
      expect(result.containsKey('firstUsableHost'), true);
      expect(result.containsKey('lastUsableHost'), true);
      expect(result.containsKey('usableRange'), true);
      expect(result.containsKey('prefix'), true);
      expect(result.containsKey('ipClass'), true);
      expect(result.containsKey('isPrivate'), true);
      expect(result.containsKey('binaryMask'), true);
    });
  });
}
