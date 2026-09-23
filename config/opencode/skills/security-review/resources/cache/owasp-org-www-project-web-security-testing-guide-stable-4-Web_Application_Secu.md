---
source: https://owasp.org/www-project-web-security-testing-guide/stable/4-Web_Application_Security_Testing/11-Client-side_Testing
fetched: 2026-07-20
---

# OWASP WSTG Client-Side Testing

Die WSTG-Client-Side-Testing-Uebersicht verweist auf Testbereiche fuer DOM-XSS, JavaScript-Ausfuehrung, HTML-Injection, clientseitige URL-Redirects, CSS-Injection, clientseitige Resource-Manipulation, CORS, WebSockets, Web Messaging, Browser Storage und Cross-Site Script Inclusion. Fuer eine statische ASVS-V1-Pruefung leitet daraus ab, clientseitige Datenfluesse von URL, Storage, Messaging und API-Antworten zu DOM-, URL-, Script-, Style- und Netzwerk-Sinks zu verfolgen. Besonders relevant sind Stellen, an denen Frontendcode HTML erzeugt, Links oder Script-/Resource-URLs dynamisch setzt, `postMessage`-Daten verarbeitet oder Browser-Storage-Werte in UI/API-Kontexte uebernimmt. Die WSTG ist testorientiert; sie ersetzt keine Codebeweise, unterstuetzt aber die Auswahl von Quellen/Sinks und die Beurteilung, ob ein Befund statisch sicher entscheidbar ist oder manuelle Laufzeitpruefung benoetigt.
