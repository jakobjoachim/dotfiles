---
source: https://cheatsheetseries.owasp.org/cheatsheets/DOM_based_XSS_Prevention_Cheat_Sheet.html
fetched: 2026-07-20
---

# OWASP DOM Based XSS Prevention Cheat Sheet

DOM-XSS entsteht clientseitig, wenn untrusted Daten aus Quellen wie URL, Storage, API-Antworten oder DOM in gefaehrliche DOM-Sinks gelangen. OWASP empfiehlt, untrusted Daten nur als Text zu behandeln und den DOM mit sicheren APIs wie `textContent`, `document.createElement`, `appendChild` und begrenzt `setAttribute` fuer harmlose, hart codierte Attribute aufzubauen. Zu vermeiden sind HTML-Rendering-Sinks wie `innerHTML`, `outerHTML`, `document.write` und `document.writeln`, sowie implizite oder explizite Codeausfuehrung durch `eval`, `new Function`, string-basierte `setTimeout`/`setInterval` und Eventhandler-Attribute. URL- und CSS-Subkontexte benoetigen zusaetzliche Validierung und Encoding; untrusted Werte duerfen nicht linksseitig in Objekteigenschaften oder in Befehls-/Handlerkontexte gelangen. Fuer Reviews sind Angular-Escape-Hatches, direkte DOM-Manipulation, OpenLayers/Map-Popups, dynamische Linkziele und Skript-/Style-Injektionen besonders relevant.
