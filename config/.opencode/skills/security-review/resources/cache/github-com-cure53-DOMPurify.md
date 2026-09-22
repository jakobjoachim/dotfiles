---
source: https://github.com/cure53/DOMPurify
fetched: 2026-07-20
---

# DOMPurify

DOMPurify ist ein browserbasierter HTML-, MathML- und SVG-Sanitizer gegen XSS. Die Standardkonfiguration ist restriktiv, erlaubt aber bewusst sicheres Markup; fuer reine HTML-Anwendungsfaelle kann `USE_PROFILES: { html: true }` genutzt werden. Ein wichtiger Footgun-Hinweis ist, dass nachtraegliche Manipulation oder Verarbeitung sanitisierten Markups durch andere Bibliotheken die Schutzwirkung aufheben kann. Server-seitige Nutzung erfordert eine sichere DOM-Implementierung; DOMPurify empfiehlt aktuelle `jsdom`-Versionen und warnt vor unsicheren DOM-Implementierungen wie `happy-dom`. DOMPurify unterstuetzt Trusted Types, inklusive Rueckgabe von `TrustedHTML` und Integration in eigene Policies. Konfigurationen wie `ADD_TAGS`, `ADD_ATTR`, `CUSTOM_ELEMENT_HANDLING`, `ALLOW_UNKNOWN_PROTOCOLS` oder geloeste URI-Regeln koennen XSS-Risiken vergroessern und muessen eng begruendet sein. Fuer Reviews sind direkte Sanitizer-Aufrufe, Konfigurationslockerungen und anschliessende Verwendung in `innerHTML`/Framework-Escape-Hatches relevant.
