---
source: https://openid.net/specs/fapi-security-profile-2_0-final.html
fetched: 2026-07-24
---

# FAPI 2.0 Security Profile

0 Security Profile fapi-security-profile-2 February 2025 Fett, et al. Standards Track [Page] Workgroup: fapi Published: 22 February 2025 Status: Final Authors: D. 0 is an API security profile suitable for high-security applications based on the OAuth 2. 0 Security Profile is an API security profile based on the OAuth 2. 0 Authorization Framework [ RFC6749 ] and related specifications that aims to reach the security goals laid out in the Attacker Model [ attackermodel ] so that it is suitable for protecting APIs in high-value scenarios. It also follows the recommendations in the OAuth Security BCP [ RFC9700 ] . ¶ This document specifies the process for a client to obtain sender-constrained tokens from an authorization server and use them securely with resource servers. ¶ The security property is formally analysed [ FAPI2SEC ] under the aforementioned attacker model. For the security assumptions, please refer the attacker model. security profile was initially developed with a focus on financial applications, it is designed to be universally applicable for protecting APIs exposing high-value and sensitive (personal and other) data, for example, in e-health and e-government applications.
