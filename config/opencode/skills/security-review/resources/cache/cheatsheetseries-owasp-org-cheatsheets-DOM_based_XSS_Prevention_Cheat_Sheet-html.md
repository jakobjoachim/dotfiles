---
source: https://cheatsheetseries.owasp.org/cheatsheets/DOM_based_XSS_Prevention_Cheat_Sheet.html
fetched: 2026-07-24
---

# DOM based XSS Prevention - OWASP Cheat Sheet Series

ptions Usually Safe Methods Detect DOM XSS using variant analysis DOM based XSS Prevention Cheat Sheet &para; Introduction &para; When looking at XSS (Cross-Site Scripting), there are three generally recognized forms of XSS : Reflected or Stored DOM Based XSS . The XSS Prevention Cheatsheet does an excellent job of addressing Reflected and Stored XSS. This cheatsheet addresses DOM (Document Object Model) based XSS and is an extension (and assumes comprehension) of the XSS Prevention Cheatsheet . In order to understand DOM based XSS, one needs to see the fundamental difference between Reflected and Stored XSS when compared to DOM based XSS. The primary difference is where the attack is injected into the application. Reflected and Stored XSS are server side injection issues while DOM based XSS is a client (browser) side injection issue. All of this code originates on the server, which means it is the application owner's responsibility to make it safe from XSS, regardless of the type of XSS flaw it is. Also, XSS attacks always execute in the browser. The difference between Reflected/Stored XSS is where the attack is added or injected into the application. With Reflected/Stored the attack is injected into the application during server-side processing of requests where untrusted input is dynamically added to HTML.
