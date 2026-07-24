---
source: https://graphql.org/learn/authorization/
fetched: 2026-07-24
---

# Authorization | GraphQL

Authorization | GraphQL Learn Resource Hub Community Blog GraphQLConf 2026 GraphQL Days GraphQL. r HTTP Errors Naming Conventions and Design Standards Schema Governance Schema Ownership and Governance Models Governance Tooling Schema Review Schema Change Management light On This Page Type and field authorization Using type system directives Recap Question? Give us feedback → Edit this page Learn Authorization Authorization Delegate authorization logic to the business logic layer Most APIs will need to secure access to certain types of data depending on who requested it, and GraphQL is no different. GraphQL execution should begin after authentication middleware confirms the user’s identity and passes that information to the GraphQL layer. But after that, you still need to determine if the authenticated user is allowed to view the data provided by the specific fields that were included in the request. On this page, we’ll explore how a GraphQL schema can support authorization. Type and field authorization Authorization is a type of business logic that describes whether a given user/session/context has permission to perform an action or see a piece of data. For example: “Only authors can see their drafts” Enforcing this behavior should happen in the business logic layer . Let’s consider the following Post type defined in a schema: type Post { authorId : ID ! reaches the server, authentication middleware will first check the user’s credentials and add information about their
