def explain_diagnostic(data: dict) -> dict:
    diag_type = data.get("type", "unknown")
    result = data.get("result", {})
    target = data.get("target", "unknown")

    explanation = ""
    likely_cause = ""
    next_steps = ""
    severity = "info"
    recommendations = []

    if diag_type == "ping":
        success = result.get("success", False)
        if not success:
            explanation = (
                f"The ping to {target} failed. The host may be unreachable "
                f"or blocking ICMP requests."
            )
            likely_cause = (
                "The host is down, unreachable, or has a firewall "
                "blocking ICMP packets."
            )
            next_steps = (
                "Try a DNS lookup to verify the hostname resolves. "
                "Check if the host is reachable on specific ports like 80 or 443."
            )
            severity = "critical"
            recommendations = [
                "Verify DNS resolution with a DNS lookup",
                "Check TCP connectivity on port 80 or 443",
                "Try pinging from a different network to rule out local issues",
                "Check if the host has ICMP filtering enabled",
            ]
        else:
            avg = result.get("avg", "N/A")
            loss = result.get("packetLoss", "0")
            explanation = (
                f"Ping to {target} succeeded with an average latency of "
                f"{avg}ms and {loss}% packet loss."
            )
            try:
                avg_val = float(avg)
                if avg_val > 200:
                    likely_cause = (
                        "High latency suggests network congestion, "
                        "geographic distance, or routing inefficiency."
                    )
                    severity = "warning"
                    recommendations = [
                        "Run a traceroute to identify slow hops",
                        "Check for network congestion or bandwidth limits",
                        "Consider using a CDN if the target is geographically distant",
                    ]
                elif avg_val > 100:
                    likely_cause = (
                        "Moderate latency. Could be geographic distance "
                        "or slightly congested routes."
                    )
                    severity = "warning"
                    recommendations = [
                        "Run a traceroute to examine the network path",
                        "Compare with pings at different times of day",
                    ]
                else:
                    likely_cause = "Network connectivity appears healthy."
                    severity = "ok"
                    recommendations = []
            except (ValueError, TypeError):
                likely_cause = "Check the raw latency values for details."

            try:
                loss_val = float(loss)
                if loss_val > 0:
                    next_steps = (
                        "Packet loss detected. Run a traceroute to identify "
                        "where packets are being dropped."
                    )
                    if severity == "ok":
                        severity = "warning"
                    recommendations.append(
                        "Run traceroute to locate the packet loss point"
                    )
                else:
                    next_steps = "Results look normal. No further action needed."
            except (ValueError, TypeError):
                next_steps = "Review the packet loss percentage."

    elif diag_type == "dns":
        success = result.get("success", False)
        if not success:
            explanation = (
                f"DNS lookup for {target} failed. The domain may not exist "
                f"or the DNS resolver is having issues."
            )
            likely_cause = "Possible NXDOMAIN, DNS server issues, or unregistered domain."
            next_steps = "Verify the domain name is correct. Try a different DNS resolver."
            severity = "critical"
            recommendations = [
                "Double-check the domain spelling",
                "Try querying a public resolver like 8.8.8.8 or 1.1.1.1",
                "Check if the domain registration has expired",
                "Verify local DNS resolver configuration",
            ]
        else:
            records = result.get("records", [])
            explanation = f"DNS lookup for {target} returned {len(records)} record(s)."
            likely_cause = "DNS is resolving correctly for this domain."
            next_steps = "No issues detected. Proceed with connectivity tests."
            severity = "ok"
            recommendations = [
                "Verify the resolved IPs match your expected infrastructure",
            ]

    elif diag_type == "port":
        is_open = result.get("open", False)
        port = result.get("port", "unknown")
        explanation = (
            f"Port {port} on {target} is {'open' if is_open else 'closed or filtered'}."
        )
        if is_open:
            likely_cause = "A service is actively listening on this port."
            next_steps = "The service is reachable. Proceed with application-level checks."
            severity = "ok"
            recommendations = [
                "Verify the service version for known vulnerabilities",
                "Check TLS configuration if this is a secure port",
            ]
        else:
            likely_cause = "No service listening, or a firewall is blocking the connection."
            next_steps = (
                "Check if the service is running. Verify firewall rules "
                "allow traffic on this port."
            )
            severity = "critical"
            recommendations = [
                "Verify the service process is running on the host",
                "Check iptables/security group rules for port access",
                "Try connecting from within the same network",
                "Check if the port number is correct",
            ]

    elif diag_type == "tls":
        success = result.get("success", False)
        if not success:
            explanation = f"TLS certificate check for {target} failed."
            likely_cause = "Server may not support TLS, or the certificate is invalid."
            next_steps = "Verify the domain supports HTTPS. Check port 443 is open."
            severity = "critical"
            recommendations = [
                "Check if port 443 is open with a port check",
                "Verify the SSL certificate is properly installed",
                "Check for certificate chain issues",
                "Ensure the server supports modern TLS versions",
            ]
        else:
            days = result.get("daysRemaining", 0)
            explanation = f"TLS certificate for {target} is valid with {days} days remaining."
            if days < 7:
                likely_cause = "Certificate is about to expire. Immediate renewal needed."
                next_steps = "Renew the certificate immediately to avoid service disruption."
                severity = "critical"
                recommendations = [
                    "Renew the certificate immediately",
                    "Set up auto-renewal with Let's Encrypt or your CA",
                    "Add a TLS monitor to get early warnings",
                ]
            elif days < 30:
                likely_cause = "Certificate is expiring soon and needs renewal."
                next_steps = "Schedule certificate renewal within the next few weeks."
                severity = "warning"
                recommendations = [
                    "Schedule certificate renewal",
                    "Set up auto-renewal to prevent future expirations",
                    "Monitor certificate expiry with a TLS monitor",
                ]
            else:
                likely_cause = "Certificate is healthy and valid."
                next_steps = "No action needed."
                severity = "ok"
                recommendations = []

    elif diag_type == "http":
        status = result.get("statusCode")
        explanation = f"HTTP check returned status code {status} for {target}."
        if status and 200 <= status < 300:
            likely_cause = "The web server is responding normally."
            severity = "ok"
            recommendations = [
                "Review response headers for security best practices",
                "Check for missing HSTS, CSP, or X-Frame-Options headers",
            ]
        elif status and 300 <= status < 400:
            likely_cause = "The server is redirecting to another URL."
            severity = "info"
            recommendations = [
                "Verify the redirect target is correct",
                "Ensure HTTPS redirects are properly configured",
            ]
        elif status and 400 <= status < 500:
            likely_cause = "Client error. The requested resource may not exist or require authentication."
            severity = "warning"
            recommendations = [
                "Verify the URL path is correct",
                "Check if authentication credentials are required",
                "Review server access logs for details",
            ]
        elif status and status >= 500:
            likely_cause = "Server error. The server is experiencing issues."
            severity = "critical"
            recommendations = [
                "Check server application logs for errors",
                "Verify server resource usage (CPU, memory, disk)",
                "Check database connectivity if applicable",
                "Review recent deployments for breaking changes",
            ]
        else:
            likely_cause = "Unable to determine the response status."
            severity = "warning"
            recommendations = []
        next_steps = "Review the response headers for security headers and caching policy."

    elif diag_type == "traceroute":
        hops = result.get("hops", [])
        explanation = f"Traceroute to {target} completed with {len(hops)} hop(s)."
        timeouts = sum(1 for h in hops if h.get("ip") == "*")
        if timeouts > 0:
            likely_cause = f"{timeouts} hop(s) did not respond, which may indicate filtered ICMP."
            next_steps = "Timeouts in the middle of the route are normal. Timeouts at the end may indicate the target is filtering packets."
            severity = "warning" if timeouts < len(hops) / 2 else "critical"
            recommendations = [
                "Check if timeouts are at intermediate or final hops",
                "Final-hop timeouts often mean ICMP is filtered but the host is reachable",
                "Try an HTTP check to verify actual reachability",
            ]
        else:
            likely_cause = "All hops responded. Network path looks clear."
            next_steps = "Check individual hop latencies for any spikes."
            severity = "ok"
            recommendations = [
                "Look for latency jumps between hops to find bottlenecks",
            ]

    elif diag_type == "reverseDns":
        success = result.get("success", False)
        if success:
            ptr = result.get("ptr", "N/A")
            explanation = f"Reverse DNS lookup for {target} returned PTR record: {ptr}."
            likely_cause = "The IP has a valid reverse DNS entry configured."
            next_steps = "No issues detected."
            severity = "ok"
            recommendations = []
        else:
            explanation = f"Reverse DNS lookup for {target} failed."
            likely_cause = "No PTR record configured for this IP address."
            next_steps = "Contact the IP owner to configure a PTR record if needed."
            severity = "info"
            recommendations = [
                "PTR records are important for email deliverability",
                "Contact your ISP or hosting provider to set up reverse DNS",
            ]

    elif diag_type == "subnet":
        explanation = f"Subnet calculation completed for {target}."
        likely_cause = "CIDR notation was parsed and network details computed."
        next_steps = "Use the results for network planning and configuration."
        severity = "ok"
        recommendations = []

    else:
        explanation = f"Diagnostic result for {target}."
        likely_cause = "Review the raw results for details."
        next_steps = "Run additional diagnostics if needed."
        severity = "info"
        recommendations = []

    return {
        "success": True,
        "explanation": explanation,
        "likelyCause": likely_cause,
        "nextSteps": next_steps,
        "severity": severity,
        "recommendations": recommendations,
    }
