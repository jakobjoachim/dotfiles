---
source: https://owasp.org/www-project-web-security-testing-guide/stable/4-Web_Application_Security_Testing/11-Client-side_Testing/10-Testing_WebSockets
fetched: 2026-07-24
---

# WSTG - Stable | OWASP Foundation

 You're viewing the current stable version of the Web Security Testing Guide project. Store Donate Join This website uses cookies to analyze our traffic and only share that information with our analytics partners. e Join WSTG - Stable Home &nbsp;>&nbsp; Stable &nbsp;>&nbsp; 4-Web Application Security Testing &nbsp;>&nbsp; 11-Client-side Testing Testing WebSockets ID WSTG-CLNT-10 Summary Traditionally, the HTTP protocol only allows one request/response per TCP connection. Origin It is the server’s responsibility to verify the Origin header in the initial HTTP WebSocket handshake. If the server does not validate the origin header in the initial WebSocket handshake, the WebSocket server may accept connections from any origin. This could allow attackers to communicate with the WebSocket server cross-domain allowing for CSRF-like issues. Confidentiality and Integrity WebSockets can be used over unencrypted TCP or over encrypted TLS. To use unencrypted WebSockets the ws:// URI scheme is used (default port 80), to use encrypted (TLS) WebSockets the wss:// URI scheme is used (default port 443). Input Sanitization As with any data originating from untrusted sources, the data should be properly sanitized and encoded. See also Top 10-2017 A1-Injection and Top 10-2017 A7-Cross-Site Scripting (XSS) .
