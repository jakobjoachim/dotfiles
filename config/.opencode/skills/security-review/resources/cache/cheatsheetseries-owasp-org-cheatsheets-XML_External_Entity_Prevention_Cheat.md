---
source: https://cheatsheetseries.owasp.org/cheatsheets/XML_External_Entity_Prevention_Cheat_Sheet.html
fetched: 2026-07-20
---

# OWASP XML External Entity Prevention Cheat Sheet

XXE entsteht, wenn untrusted XML mit schwach konfigurierten Parsern verarbeitet wird und externe Entitaeten, DTDs oder XInclude Ressourcen laden koennen. OWASP empfiehlt als sicherste Massnahme, DTDs vollstaendig zu deaktivieren und zusaetzlich externe General-/Parameter-Entities, externe DTDs, XInclude und externe Schema-/Stylesheet-Zugriffe zu sperren; Secure Processing und Expansionslimits schuetzen gegen DoS. Fuer Java nennt die Quelle konkrete JAXP-/StAX-/Transformer-/Validator-Konfigurationen wie `disallow-doctype-decl`, `external-general-entities=false`, `external-parameter-entities=false`, `load-external-dtd=false`, `XMLConstants.ACCESS_EXTERNAL_*=""` und `XMLConstants.FEATURE_SECURE_PROCESSING=true`. `java.beans.XMLDecoder` gilt als grundsaetzlich unsicher fuer untrusted Eingaben. Fuer statische Reviews sind `DocumentBuilderFactory`, `SAXParserFactory`, `XMLInputFactory`, `TransformerFactory`, `SchemaFactory`, `XPathExpression`, JAXB-Unmarshaller und Drittbibliotheken mit XML-Verarbeitung relevant.
