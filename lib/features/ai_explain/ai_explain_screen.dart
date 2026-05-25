import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_noc/core/theme/app_theme.dart';
import 'package:pocket_noc/core/services/api_service.dart';

class AiExplainScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> diagnosticData;

  const AiExplainScreen({super.key, required this.diagnosticData});

  @override
  ConsumerState<AiExplainScreen> createState() => _AiExplainScreenState();
}

class _AiExplainScreenState extends ConsumerState<AiExplainScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _explanation;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchExplanation();
  }

  Future<void> _fetchExplanation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ApiService().explainResult(widget.diagnosticData);
      if (result['success'] == false) {
        setState(() {
          _isLoading = false;
          _error = result['error'] as String? ?? 'Failed to get explanation';
          _explanation = _generateOfflineExplanation();
        });
      } else {
        setState(() {
          _isLoading = false;
          _explanation = result;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Could not reach the server. Showing basic analysis.';
        _explanation = _generateOfflineExplanation();
      });
    }
  }

  Map<String, dynamic> _generateOfflineExplanation() {
    final type = widget.diagnosticData['type'] as String? ?? 'unknown';
    final result =
        widget.diagnosticData['result'] as Map<String, dynamic>? ?? {};
    final target = widget.diagnosticData['target'] as String? ?? 'unknown';

    String explanation;
    String likelyCause;
    String nextSteps;
    String severity = 'info';
    List<String> recommendations = [];

    switch (type) {
      case 'ping':
        final success = result['success'] == true;
        final loss = result['packetLoss'];
        if (!success) {
          explanation =
              'The ping to $target failed. The host may be unreachable or blocking ICMP.';
          likelyCause =
              'The host is down, unreachable, or has a firewall blocking ICMP packets.';
          nextSteps =
              'Try a DNS lookup to verify the hostname resolves. Check if the host is reachable on specific ports.';
          severity = 'critical';
          recommendations = [
            'Verify DNS resolution with a DNS lookup',
            'Check TCP connectivity on port 80 or 443',
            'Try pinging from a different network',
          ];
        } else {
          final avg = result['avg'] ?? 'N/A';
          explanation =
              'Ping to $target succeeded with an average latency of ${avg}ms and $loss% packet loss.';
          likelyCause = double.tryParse('$avg') != null &&
                  double.parse('$avg') > 100
              ? 'High latency may indicate network congestion, geographic distance, or routing issues.'
              : 'Network connectivity to the target appears healthy.';
          nextSteps = double.tryParse('$loss') != null &&
                  double.parse('$loss') > 0
              ? 'Packet loss detected. Run a traceroute to identify where packets are being dropped.'
              : 'Results look normal. No further action needed.';
          severity = double.tryParse('$avg') != null &&
                  double.parse('$avg') > 100
              ? 'warning'
              : 'ok';
        }

      case 'dns':
        final success = result['success'] == true;
        if (!success) {
          explanation =
              'DNS lookup for $target failed. The domain may not exist or the resolver cannot reach it.';
          likelyCause =
              'Possible NXDOMAIN, DNS server issues, or the domain is not registered.';
          nextSteps =
              'Verify the domain name is correct. Try a different DNS resolver.';
          severity = 'critical';
          recommendations = [
            'Double-check the domain spelling',
            'Try a public resolver like 8.8.8.8',
          ];
        } else {
          final records = result['records'] as List? ?? [];
          explanation =
              'DNS lookup for $target returned ${records.length} record(s).';
          likelyCause = 'DNS is resolving correctly for this domain.';
          nextSteps =
              'No issues detected. You can proceed with connectivity tests.';
          severity = 'ok';
        }

      case 'port':
        final open = result['open'] == true;
        explanation = open
            ? 'Port on $target is open and accepting TCP connections.'
            : 'Port on $target is closed or filtered.';
        likelyCause = open
            ? 'A service is listening on this port.'
            : 'No service is listening, or a firewall is blocking the connection.';
        nextSteps = open
            ? 'The service is reachable. You can proceed with application-level checks.'
            : 'Check if the service is running. Verify firewall rules allow traffic on this port.';
        severity = open ? 'ok' : 'critical';

      case 'tls':
        final success = result['success'] == true;
        if (!success) {
          explanation = 'TLS certificate check for $target failed.';
          likelyCause =
              'The server may not support TLS, or the certificate is invalid.';
          nextSteps =
              'Verify the domain supports HTTPS. Check port 443 is open.';
          severity = 'critical';
        } else {
          final days = result['daysRemaining'] ?? 0;
          explanation =
              'TLS certificate for $target is valid with $days days remaining.';
          likelyCause = days < 30
              ? 'Certificate is expiring soon and needs renewal.'
              : 'Certificate is healthy.';
          nextSteps = days < 30
              ? 'Renew the certificate before it expires to avoid service disruption.'
              : 'No action needed. Certificate is valid.';
          severity = days < 7
              ? 'critical'
              : days < 30
                  ? 'warning'
                  : 'ok';
        }

      case 'http':
        final status = result['statusCode'];
        explanation = 'HTTP check returned status code $status for $target.';
        likelyCause = status != null && status >= 200 && status < 300
            ? 'The web server is responding normally.'
            : status != null && status >= 300 && status < 400
                ? 'The server is redirecting to another URL.'
                : 'The server returned an error response.';
        nextSteps =
            'Review the response headers for security best practices.';
        severity = status != null && status >= 200 && status < 300
            ? 'ok'
            : status != null && status >= 500
                ? 'critical'
                : 'warning';

      case 'traceroute':
        final hops = result['hops'] as List? ?? [];
        explanation =
            'Traceroute to $target completed with ${hops.length} hop(s).';
        likelyCause =
            'Shows the network path from your device to the target.';
        nextSteps =
            'Look for hops with high latency or timeouts to identify network bottlenecks.';
        severity = 'ok';

      default:
        explanation = 'Diagnostic result for $target.';
        likelyCause = 'Review the raw results for details.';
        nextSteps = 'Run additional diagnostics if needed.';
    }

    return {
      'explanation': explanation,
      'likelyCause': likelyCause,
      'nextSteps': nextSteps,
      'severity': severity,
      'recommendations': recommendations,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final type = widget.diagnosticData['type'] as String? ?? 'Diagnostic';

    return Scaffold(
      appBar: AppBar(
        title: Text('AI Analysis: ${type.toUpperCase()}'),
        actions: [
          if (_explanation != null)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                final text = 'Explanation: ${_explanation!['explanation']}\n\n'
                    'Likely Cause: ${_explanation!['likelyCause']}\n\n'
                    'Next Steps: ${_explanation!['nextSteps']}';
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Analyzing results...',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: AppColors.warning, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: AppColors.warning)),
                          ),
                        ],
                      ),
                    ),
                  if (_explanation != null) ...[
                    // Severity badge
                    _SeverityBanner(
                      severity: _explanation!['severity'] as String? ?? 'info',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _ExplainCard(
                      icon: Icons.lightbulb_outline,
                      title: 'What happened',
                      content: _explanation!['explanation'] ?? '',
                      color: AppColors.info,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _ExplainCard(
                      icon: Icons.search,
                      title: 'Likely cause',
                      content: _explanation!['likelyCause'] ?? '',
                      color: AppColors.warning,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _ExplainCard(
                      icon: Icons.arrow_forward,
                      title: 'Suggested next steps',
                      content: _explanation!['nextSteps'] ?? '',
                      color: AppColors.success,
                      isDark: isDark,
                    ),

                    // Recommendations
                    if (_explanation!['recommendations'] != null &&
                        (_explanation!['recommendations'] as List).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _RecommendationsCard(
                        recommendations: List<String>.from(
                            _explanation!['recommendations'] as List),
                        isDark: isDark,
                      ),
                    ],

                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : AppColors.lightBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'This is an AI-assisted analysis and may not be '
                        'fully accurate. It is meant to help you understand '
                        'the results, not provide a guaranteed diagnosis.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _SeverityBanner extends StatelessWidget {
  final String severity;
  final bool isDark;

  const _SeverityBanner({required this.severity, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color color;
    IconData icon;
    String label;

    switch (severity) {
      case 'ok':
        color = AppColors.success;
        icon = Icons.check_circle;
        label = 'All Clear';
      case 'warning':
        color = AppColors.warning;
        icon = Icons.warning_amber;
        label = 'Needs Attention';
      case 'critical':
        color = AppColors.error;
        icon = Icons.error;
        label = 'Critical Issue';
      default:
        color = AppColors.info;
        icon = Icons.info_outline;
        label = 'Informational';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(label,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _RecommendationsCard extends StatelessWidget {
  final List<String> recommendations;
  final bool isDark;

  const _RecommendationsCard(
      {required this.recommendations, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.checklist, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text('Recommendations',
                    style: theme.textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: 12),
            ...recommendations.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text('${entry.key + 1}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(entry.value,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              height: 1.4,
                            )),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _ExplainCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color color;
  final bool isDark;

  const _ExplainCard({
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
