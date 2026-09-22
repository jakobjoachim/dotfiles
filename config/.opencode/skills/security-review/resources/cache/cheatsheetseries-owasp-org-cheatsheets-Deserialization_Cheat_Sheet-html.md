---
source: https://cheatsheetseries.owasp.org/cheatsheets/Deserialization_Cheat_Sheet.html
fetched: 2026-07-20
---

# OWASP Deserialization Cheat Sheet

Unsichere Deserialisierung tritt auf, wenn untrusted Daten native Objektgraphen oder polymorphe Typen steuern koennen. OWASP empfiehlt, native Formate fuer untrusted Daten zu vermeiden und stattdessen reine Datenformate wie JSON mit DTOs zu nutzen. Fuer Java sind besonders `ObjectInputStream.readObject`, `XMLDecoder`, `XStream.fromXML`, `readResolve`, `readExternal` und generische polymorphe Deserialisierung relevant. Sichere Muster sind Allowlisting erwarteter Klassen durch ueberschriebene `ObjectInputStream#resolveClass`, ValidatingObjectInputStream-Varianten, sichere Bibliothekskonfigurationen und Vermeidung von Domain-Objekt-Deserialisierung aus externen Eingaben. `java.beans.XMLDecoder` wird als nicht sicher absicherbar fuer untrusted Input beschrieben. JSON-Bibliotheken sind meist sicher, solange keine unsichere Polymorphie oder Autotype-Funktion aktiviert ist; bei Jackson sind Default Typing/polymorphe Typinformationen kritisch. Fuer Reviews sind Suchmuster nach Serialisierungsklassen, Framework-Bindern und Bibliotheken mit Typmetadaten entscheidend.
