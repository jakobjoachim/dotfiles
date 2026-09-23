import { tool, type Plugin } from "@opencode-ai/plugin"
import { findOciRegistryVersions } from "../lib/oci-registry-versions"

export const findGcrVersions = (input: { image: string; platform?: string }, signal?: AbortSignal) =>
  findOciRegistryVersions(input, { label: "GCR.io", hosts: /^(?:us\.|eu\.|asia\.)?gcr\.io$/ }, signal)

export default (async () => ({
  tool: {
    gcr_versions: tool({
      description: "Deterministically find stable GCR.io image versions and flag newer versions that require a flavor migration.",
      args: {
        image: tool.schema.string().describe("Current GCR.io image reference, including its tag or digest"),
        platform: tool.schema.string().optional().describe("Optional target platform, for example linux/amd64"),
      },
      async execute(args, context) {
        return JSON.stringify(await findGcrVersions(args, context.abort), null, 2)
      },
    }),
  },
})) satisfies Plugin
