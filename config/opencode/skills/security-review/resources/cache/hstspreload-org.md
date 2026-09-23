---
source: https://hstspreload.org/
fetched: 2026-07-24
---

# HSTS Preload List Submission

HSTS Preload List Submission On GitHub HTTP Strict Transport Security (HSTS) HTTP Strict Transport Security (HSTS) is a mechanism for websites to instruct web browsers that the site should only be accessed over HTTPS. This mechanism works by sites sending a Strict-Transport-Security HTTP response header containing the site's policy. A site that enables HSTS helps protect its users from the following attacks done by an on-path attacker: Browsing history leaks : If a user clicks on an HTTP link to a site, an on-path network observer can see that URL. Protocol downgrades : If a site redirects from HTTP to HTTPS, an on-path network attacker can intercept and re-write the redirect to keep the browser using plaintext HTTP. Cookie hijacking : On HTTP requests, an on-path network attacker can see and modify cookies. Even if the site redirects to HTTPS, the on-path attacker can inject cookies into the redirect response. e max-age in stages, using the following header values: 5 minutes: max-age=300; includeSubDomains 1 week: max-age=604800; includeSubDomains 1 month: max-age=2592000; includeSubDomains During each stage, check for broken pages and monitor your site's metrics (e. Consult the Mozilla Web Security guidelines and the Google Web Fundamentals pages on security for more concrete advice about HTTPS deployment. HSTS preloading only provides value when these upgrades fail in the presence of an active attacker. Submission Requirements If a site sends the preload directive
