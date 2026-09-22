---
source: https://datatracker.ietf.org/doc/html/rfc4180#section-2
fetched: 2026-07-20
---

# RFC 4180 CSV Format

RFC 4180 beschreibt das allgemein uebliche CSV-Format: Datensaetze sind durch CRLF getrennt, optionale Header haben die gleiche Feldanzahl wie Datenzeilen, Felder sind kommasepariert und koennen in doppelte Anfuehrungszeichen eingeschlossen werden. Felder mit Zeilenumbruechen, Kommas oder doppelten Anfuehrungszeichen muessen quotiert werden; innere doppelte Anfuehrungszeichen werden durch Verdopplung escaped. Fuer ASVS V1.2.10 waere zusaetzlich Spreadsheet-Formula-Injection relevant, wenn CSV/XLSX/ODS exportiert wird: Werte, die mit `=`, `+`, `-`, `@`, Tab oder Null beginnen, muessen vor Tabellenkalkulationsprogrammen neutralisiert werden. Da V1.2.10 Level 3 ist, ist dies bei Level 2 nicht im Scope, kann aber bei gefundenen Exportfunktionen als Kontextnotiz auftauchen.
