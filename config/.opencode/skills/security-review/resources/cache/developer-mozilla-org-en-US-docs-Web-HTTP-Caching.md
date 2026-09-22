---
source: https://developer.mozilla.org/en-US/docs/Web/HTTP/Caching
fetched: 2026-07-24
---

# HTTP caching - HTTP | MDN

 Also, when a response is reusable, the origin server does not need to process the request — so it does not need to parse and route the request, restore the session based on the cookie, query the DB for results, or render the template engine. e Expires or max-age Vary Validation Don't cache Reload and force reload Deleting stored responses Request collapse Common caching patterns See also Types of caches In the HTTP Caching spec, there are two main types of caches: private caches and shared caches . http Cache-Control: private Personalized contents are usually controlled by cookies, but the presence of a cookie does not always indicate that it is private, and thus a cookie alone does not make the response private. This is usually not managed by the service developer, so it must be controlled by appropriate HTTP headers and so on. Kitchen-sink headers like the following are used to try to work around "old and not updated proxy cache" implementations that do not understand current HTTP Caching spec directives like no-store . o-cache, max-age=0, must-revalidate, proxy-revalidate However, in recent years, as HTTPS has become more common and client/server communication has become encrypted, proxy caches in the path can only tunnel a response and can't behave as a cache, in many cases. On the other hand, if a TLS bridge proxy decrypts all communications in a person-in-the-middle
