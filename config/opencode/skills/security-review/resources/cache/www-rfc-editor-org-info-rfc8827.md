---
source: https://www.rfc-editor.org/info/rfc8827
fetched: 2026-07-24
---

# RFC 8827: WebRTC Security Architecture | RFC Editor

RFC 8827: WebRTC Security Architecture | RFC Editor Your browser has JavaScript disabled. r reading RFCs Browse all RFCs Download RFCs Errata in RFCs FAQ For Authors How to write an RFC Independent Submissions Style Guide RFC Publication Process Document Queue About Us About RFC Editor Reports Privacy Statement Contact The RFC Series What is an RFC? w to write an RFC Independent Submissions Style Guide RFC Publication Process Document Queue About Us About RFC Editor Reports Privacy Statement Contact Search Your preferences Theme RFC Info pages Home RFC 8827 Info RFC   8827 : WebRTC Security Architecture E. Rescorla Proposed Standard Abstract This document defines the security architecture for WebRTC, a protocol suite intended for use with real-time applications that can be deployed in browsers -- "real-time communication on the Web". ¶ Copyright Notice Copyright (c) 2021 IETF Trust and the persons identified as the document authors. Introduction The Real-Time Communications on the Web (RTCWEB) Working Group standardized protocols for real-time communications between Web browsers, generally called "WebRTC" [ RFC8825 ] . The major use cases for WebRTC technology are real-time audio and/or video calls, Web conferencing, and direct data transfer. , SIP-based [ RFC3261 ] soft phones), WebRTC communications are directly controlled by some Web server, via a JavaScript (JS) API as shown in Figure 1 . P / \ / \ v v JS API JS API
