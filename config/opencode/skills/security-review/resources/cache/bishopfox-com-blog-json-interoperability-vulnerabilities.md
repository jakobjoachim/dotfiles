---
source: https://bishopfox.com/blog/json-interoperability-vulnerabilities
fetched: 2026-07-20
---

# Bishop Fox JSON Interoperability Vulnerabilities

Der Beitrag zeigt, dass unterschiedliche JSON-Parser denselben JSON-String unterschiedlich interpretieren koennen. Sicherheitsrelevant sind doppelte Keys mit unterschiedlicher Praezedenz, Key-Kollisionen durch Zeichen-/Unicode-Trunkierung oder Kommentarunterstuetzung, Serialisierung, die doppelte Keys erhaelt, sowie unterschiedliche Behandlung sehr grosser Zahlen, `Infinity` oder `NaN`. Besonders riskant sind Architekturen, in denen ein Dienst JSON parst und validiert, aber den urspruenglichen Rohstring an einen anderen Dienst mit anderem Parser weiterreicht. JSON Schema validiert nur das bereits geparste Objekt und erkennt doppelte Keys im Rohtext nicht. Empfohlene Gegenmassnahmen sind ein Parser-Inventar, striktes Parsen, Fehler bei doppelten Keys und nicht exakt darstellbaren Zahlen, keine Weitergabe validierter Rohdaten ohne Re-Serialisierung in kanonischer Form sowie Typ-/Bereichsvalidierung vor Business-Logik. Fuer ASVS V1 ist dies vor allem bei API-Gateways, Microservices und mehrstufiger JSON-Verarbeitung relevant.
