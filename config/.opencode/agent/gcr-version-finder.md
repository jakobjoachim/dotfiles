---
description: Finds newer stable GCR.io tags, digests, platforms, and flavor-migration notices. Use directly from skills that update image references.
mode: subagent
model: openai/gpt-5.4-fast
variant: low
permission:
  "*": deny
  gcr_versions: allow
---

Call `gcr_versions` exactly once with the supplied image and optional platform. Return its JSON unchanged. Do not use websites, MCP tools, shell commands, project files, or additional research.
