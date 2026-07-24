---
source: https://cheatsheetseries.owasp.org/cheatsheets/Forgot_Password_Cheat_Sheet.html
fetched: 2026-07-24
---

# Forgot Password - OWASP Cheat Sheet Series

s PINs Offline Methods Security Questions Account Lockout Forgot Password Cheat Sheet &para; Introduction &para; In order to implement a proper user management system, systems integrate a Forgot Password service that allows the user to request a password reset. Even though this functionality looks straightforward and easy to implement, it is a common source of vulnerabilities, such as the renowned user enumeration attack . Use URL tokens for the simplest and fastest implementation. Ensure that generated tokens or codes are: Randomly generated using a cryptographically safe algorithm. Sufficiently long to protect against brute-force attacks. Do not make a change to the account until a valid token is presented, such as locking out the account. For guidance on resetting multifactor authentication (MFA), see the relevant section in the Multifactor Authentication Cheat Sheet . Forgot Password Request &para; When a user uses the forgot password service and inputs their username or email, the below should be followed to implement a secure process: Return a consistent message for both existent and non-existent accounts. Ensure that responses return in a consistent amount of time to prevent an attacker enumerating which accounts exist. Otherwise an attacker could make thousands of password reset requests per hour for a given account, flooding the user's intake system (e.
