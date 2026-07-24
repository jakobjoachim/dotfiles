---
source: https://cheatsheetseries.owasp.org/cheatsheets/LDAP_Injection_Prevention_Cheat_Sheet.html
fetched: 2026-07-20
---

# OWASP LDAP Injection Prevention Cheat Sheet

LDAP-Injection entsteht, wenn Anwendungen LDAP-DNs oder Suchfilter mit untrusted Input zusammenbauen. Die zentrale Abwehr ist kontextspezifisches Escaping: DN-Werte und Suchfilter haben unterschiedliche Metazeichen und muessen mit passenden Encodern behandelt werden. Fuer Java zeigt die Quelle sichere Suchfilter mit Platzhaltern, z. B. `ctx.search(..., "(&(uid={0})(objectClass=person))", new Object[]{ userInput }, ...)`, statt String-Konkatenation. Zusaetzlich empfiehlt OWASP Frameworks, die LDAP-Encoding automatisch anwenden, Allowlist-Validierung und Least Privilege fuer den LDAP-Bind-Account. Unsicher sind direkte Konkatenationen wie `"(&(uid=" + userInput + ")...)"`, insbesondere bei Authentifizierung oder directory-backed Benutzer-/Rollenabfragen. Fuer die statische Pruefung sind relevante Indikatoren `javax.naming`, `DirContext.search`, LDAP-URLs, DN-/Filter-Builder sowie manuelle Filterstrings mit Requestparametern.
