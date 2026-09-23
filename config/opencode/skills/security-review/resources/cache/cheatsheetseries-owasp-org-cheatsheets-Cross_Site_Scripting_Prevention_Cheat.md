---
source: https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html
fetched: 2026-07-20
---

# OWASP Cross Site Scripting Prevention Cheat Sheet

OWASP empfiehlt XSS-Schutz primaer durch Framework-Autoescaping, sichere DOM-Sinks und kontextspezifisches Output-Encoding unmittelbar am Interpreter-Kontext. HTML-Body, HTML-Attribute, JavaScript, CSS und URL-Kontexte benoetigen unterschiedliche Encoding-Regeln; falsches oder zu fruehes Encoding kann Schutzwirkung verlieren oder Double-Encoding erzeugen. Moderne Frameworks wie Angular schuetzen Standard-Interpolation, aber Escape-Hatches wie `innerHTML`, `bypassSecurityTrustAs*`, unsichere URL-Protokolle und dynamische Scripts muessen gesondert geprueft werden. Fuer HTML-Eingaben, die als Markup erhalten bleiben sollen, ist ein gepflegter Sanitizer wie DOMPurify empfohlen; nachtraegliches Veraendern sanitisierten Markups kann den Schutz aufheben. Sichere DOM-Sinks sind u. a. `textContent`, `createTextNode`, `value` und hart codierte harmlose Attribute; unsicher sind `innerHTML`, `outerHTML`, `document.write`, Eventhandler-Attribute und inline JavaScript mit untrusted Daten. CSP gilt nur als Defense-in-Depth, nicht als Ersatz fuer Encoding/Sanitization.
