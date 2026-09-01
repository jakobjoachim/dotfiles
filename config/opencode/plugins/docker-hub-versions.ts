import { tool, type Plugin } from "@opencode-ai/plugin"

type HubImage = {
  architecture: string
  digest: string
  os: string
  variant?: string | null
}

type HubTag = {
  digest: string
  images: HubImage[]
  name: string
  tag_last_pushed: string
}

type HubPage = {
  next: string | null
  results: HubTag[]
}

type Version = {
  major: number
  minor: number
  patch: number
  precision: number
  flavor: string
}

const prerelease = /(?:^|[-_.])(alpha|beta|rc|preview|dev|nightly|edge|canary|main|master)(?:\d|$|[-_.])/i

function parseReference(reference: string) {
  let value = reference.trim().replace(/^docker:\/\//, "")
  const at = value.indexOf("@")
  const digest = at >= 0 ? value.slice(at + 1) : undefined
  if (at >= 0) value = value.slice(0, at)

  const parts = value.split("/")
  const first = parts[0]
  const hasRegistry = parts.length > 1 && (first.includes(".") || first.includes(":") || first === "localhost")
  if (hasRegistry) {
    if (first !== "docker.io" && first !== "registry-1.docker.io") {
      throw new Error(`Unsupported registry: ${first}`)
    }
    parts.shift()
  }

  const last = parts.at(-1) ?? ""
  const colon = last.lastIndexOf(":")
  const tag = colon >= 0 ? last.slice(colon + 1) : digest ? undefined : "latest"
  if (colon >= 0) parts[parts.length - 1] = last.slice(0, colon)
  if (parts.length === 1) parts.unshift("library")
  if (parts.length !== 2 || parts.some((part) => !part)) {
    throw new Error(`Invalid Docker Hub image reference: ${reference}`)
  }

  return { namespace: parts[0], repository: parts[1], tag, digest }
}

function parseVersion(tag: string): Version | undefined {
  const match = tag.match(/^v?(\d+)\.(\d+)(?:\.(\d+))?(.*)$/)
  if (!match || prerelease.test(match[4])) return undefined
  return {
    major: Number(match[1]),
    minor: Number(match[2]),
    patch: match[3] === undefined ? -1 : Number(match[3]),
    precision: match[3] === undefined ? 2 : 3,
    flavor: match[4].replace(/^[-_.]+/, ""),
  }
}

function compareVersions(left: Version, right: Version) {
  return left.major - right.major || left.minor - right.minor || left.patch - right.patch || left.precision - right.precision
}

function supportsPlatform(tag: HubTag, platform?: string) {
  if (!platform) return true
  const [os, architecture, variant] = platform.split("/")
  return tag.images.some((image) =>
    image.os === os && image.architecture === architecture && (!variant || image.variant === variant),
  )
}

function platforms(tag: HubTag) {
  return [...new Set(tag.images
    .filter((image) => image.os !== "unknown" && image.architecture !== "unknown")
    .map((image) => `${image.os}/${image.architecture}${image.variant ? `/${image.variant}` : ""}`))]
}

function candidate(tag: HubTag) {
  return {
    tag: tag.name,
    digest: tag.digest,
    pushed: tag.tag_last_pushed,
    platforms: platforms(tag),
  }
}

function versionName(version: Version) {
  return `${version.major}.${version.minor}${version.patch >= 0 ? `.${version.patch}` : ""}`
}

async function getJson<T>(url: string, signal?: AbortSignal): Promise<T> {
  const response = await fetch(url, {
    headers: { Accept: "application/json" },
    signal,
  })
  if (!response.ok) throw new Error(`Docker Hub returned ${response.status} for ${url}`)
  return response.json() as Promise<T>
}

export async function findDockerHubVersions(
  input: { image: string; platform?: string },
  signal?: AbortSignal,
) {
  const reference = parseReference(input.image)
  const root = `https://hub.docker.com/v2/repositories/${encodeURIComponent(reference.namespace)}/${encodeURIComponent(reference.repository)}/tags`
  const inputVersion = reference.tag ? parseVersion(reference.tag) : undefined
  const flavorQuery = inputVersion?.flavor ? `&name=${encodeURIComponent(inputVersion.flavor)}` : ""
  let next: string | null = `${root}?page_size=100&ordering=last_updated${flavorQuery}`
  const tags: HubTag[] = []
  let pagesFetched = 0

  while (next) {
    if (pagesFetched >= 100) throw new Error("Docker Hub pagination exceeded 100 pages")
    const page: HubPage = await getJson<HubPage>(next, signal)
    tags.push(...page.results)
    next = page.next
    pagesFetched++
  }

  const currentTag = reference.tag
    ? await getJson<HubTag>(`${root}/${encodeURIComponent(reference.tag)}`, signal)
    : tags.find((tag) => tag.digest === reference.digest || tag.images.some((image) => image.digest === reference.digest))
  if (!currentTag) throw new Error(`Current image was not found on Docker Hub: ${input.image}`)

  let currentVersion = inputVersion ?? parseVersion(currentTag.name)
  if (!currentVersion) {
    const aliases = tags
      .filter((tag) => tag.digest === currentTag.digest)
      .map((tag) => ({ tag, version: parseVersion(tag.name) }))
      .filter((entry): entry is { tag: HubTag; version: Version } => Boolean(entry.version))
      .sort((left, right) => compareVersions(right.version, left.version))
    currentVersion = aliases[0]?.version
  }

  const suppliedDigestMatches = !reference.digest
    || currentTag.digest === reference.digest
    || currentTag.images.some((image) => image.digest === reference.digest)

  if (!currentVersion) {
    return {
      image: `docker.io/${reference.namespace}/${reference.repository}`,
      current: currentTag.name,
      current_digest: currentTag.digest,
      platform: input.platform ?? "unconstrained",
      candidates: null,
      recommendation: null,
      confidence: "low",
      caveats: ["Current tag does not expose a numeric version scheme"],
      pages_fetched: pagesFetched,
      source: root,
    }
  }

  const viable = tags
    .map((tag) => ({ tag, version: parseVersion(tag.name) }))
    .filter((entry): entry is { tag: HubTag; version: Version } => Boolean(entry.version))
    .filter((entry) => entry.version.flavor === currentVersion.flavor)
    .filter((entry) => entry.version.precision >= currentVersion.precision)
    .filter((entry) => compareVersions(entry.version, currentVersion) > 0)
    .filter((entry) => supportsPlatform(entry.tag, input.platform))
    .sort((left, right) => compareVersions(right.version, left.version))

  const newest = (predicate: (version: Version) => boolean) => {
    const match = viable.find((entry) => predicate(entry.version))
    return match ? candidate(match.tag) : null
  }
  const patch = newest((version) => version.major === currentVersion.major && version.minor === currentVersion.minor)
  const minor = newest((version) => version.major === currentVersion.major)
  const latest = newest(() => true)
  let migrationNotice = null
  let migrationProbeError: string | undefined

  if (currentVersion.flavor) {
    try {
      const recent = await getJson<HubPage>(`${root}?page_size=100&ordering=last_updated`, signal)
      const exactFlavorVersion = latest ? parseVersion(latest.tag) ?? currentVersion : currentVersion
      const migrations = recent.results
        .map((tag) => ({ tag, version: parseVersion(tag.name) }))
        .filter((entry): entry is { tag: HubTag; version: Version } => Boolean(entry.version))
        .filter((entry) => entry.version.flavor !== currentVersion.flavor)
        .filter((entry) => entry.version.precision >= currentVersion.precision)
        .filter((entry) => compareVersions(entry.version, exactFlavorVersion) > 0)
        .filter((entry) => supportsPlatform(entry.tag, input.platform))
        .sort((left, right) => compareVersions(right.version, left.version))

      if (migrations.length) {
        const newestObserved = migrations[0].version
        const evidence = migrations
          .filter((entry) => compareVersions(entry.version, newestObserved) === 0)
          .filter((entry, index, entries) => entries.findIndex((other) => other.version.flavor === entry.version.flavor) === index)
          .slice(0, 3)
          .map((entry) => ({ tag: entry.tag.name, digest: entry.tag.digest, pushed: entry.tag.tag_last_pushed }))
        migrationNotice = {
          newer_versions_exist: true,
          newest_observed_version: versionName(newestObserved),
          current_flavor_latest_pushed: latest?.pushed ?? currentTag.tag_last_pushed,
          requires_flavor_change: true,
          message: `The ${currentVersion.flavor} line ends at ${latest?.tag ?? currentTag.name}. Newer image versions were observed but require an explicit flavor migration.`,
          evidence,
        }
      }
    } catch (error) {
      migrationProbeError = `Flavor migration probe failed: ${error instanceof Error ? error.message : String(error)}`
    }
  }

  return {
    image: `docker.io/${reference.namespace}/${reference.repository}`,
    current: currentTag.name,
    current_digest: reference.digest ?? currentTag.digest,
    current_tag_digest: currentTag.digest,
    scheme: "numeric",
    flavor: currentVersion.flavor || "none",
    platform: input.platform ?? "unconstrained",
    candidates: { patch, minor, latest },
    recommendation: latest?.tag ?? null,
    recommended_digest: latest?.digest ?? null,
    migration_notice: migrationNotice,
    confidence: "high",
    caveats: [
      ...(!suppliedDigestMatches ? ["Supplied digest no longer matches the current tag manifest"] : []),
      ...(!latest ? ["No newer matching stable tag found"] : []),
      ...(migrationProbeError ? [migrationProbeError] : []),
    ],
    pages_fetched: pagesFetched,
    source: root,
  }
}

export default (async () => ({
  tool: {
    docker_hub_versions: tool({
      description: "Deterministically find stable Docker Hub image versions and flag newer versions that require a flavor migration.",
      args: {
        image: tool.schema.string().describe("Current Docker Hub image reference, including its tag or digest"),
        platform: tool.schema.string().optional().describe("Optional target platform, for example linux/amd64"),
      },
      async execute(args, context) {
        return JSON.stringify(await findDockerHubVersions(args, context.abort), null, 2)
      },
    }),
  },
})) satisfies Plugin
