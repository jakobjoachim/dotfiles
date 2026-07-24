---
source: https://cheatsheetseries.owasp.org/cheatsheets/Transport_Layer_Security_Cheat_Sheet.html
fetched: 2026-07-24
---

# Transport Layer Security - OWASP Cheat Sheet Series

 Certificates and Mutual TLS Public Key Pinning Related Articles Transport Layer Security Cheat Sheet &para; Introduction &para; This cheat sheet provides guidance on implementing transport layer protection for applications using Transport Layer Security (TLS). It primarily focuses on how to use TLS to protect clients connecting to a web application over HTTPS, though much of this guidance is also applicable to other uses of TLS. When correctly implemented, TLS can provide several security benefits: Confidentiality : Provides protection against attackers reading the contents of the traffic. Integrity : Provides protection against traffic modification, such as an attacker replaying requests against the server. Authentication : Enables the client to confirm they are connected to the legitimate server. SSL vs TLS &para; Secure Socket Layer (SSL) was the original protocol that was used to provide encryption for HTTP traffic, in the form of HTTPS. Both of these have serious cryptographic weaknesses and should no longer be used. 1) was named Transport Layer Security (TLS) version 1. The terms "SSL", "SSL/TLS" and "TLS" are frequently used interchangeably, and in many cases "SSL" is used when referring to the more modern TLS protocol. This cheat sheet will use the term "TLS" except where referring to the legacy protocols.
