---
source: https://datatracker.ietf.org/doc/html/rfc7636
fetched: 2026-07-24
---

# RFC 7636 - Proof Key for Code Exchange by OAuth Public Clients

op-09 draft-ietf-oauth-spop-08 draft-ietf-oauth-spop-07 draft-ietf-oauth-spop-06 draft-ietf-oauth-spop-05 draft-ietf-oauth-spop-04 draft-ietf-oauth-spop-03 draft-ietf-oauth-spop-02 draft-ietf-oauth-spop-01 draft-ietf-oauth-spop-00 Side-by-side Inline Authors N. Agarwal Email authors RFC stream Other formats txt html w/errata bibtex Additional resources Mailing list discussion Report a bug Internet Engineering Task Force (IETF) N. Agarwal Google September 2015 Proof Key for Code Exchange by OAuth Public Clients Abstract OAuth 2. 0 public clients utilizing the Authorization Code Grant are susceptible to the authorization code interception attack. This specification describes the attack as well as a technique to mitigate against the threat through the use of Proof Key for Code Exchange (PKCE, pronounced "pixy"). Copyright Notice Copyright (c) 2015 IETF Trust and the persons identified as the document authors. Standards Track [Page 1] RFC 7636 OAUTH PKCE September 2015 Table of Contents 1 . Client Sends the Code Challenge with the Authorization Request . Client Sends the Authorization Code and the Code Verifier to the Token Endpoint . Server Verifies code_verifier before Returning the Tokens .
