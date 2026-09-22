type Registry = {
  label: string
  hosts: RegExp
}

type Manifest = {
  config?: { digest: string }
  manifests?: Array<{
    digest: string
    platform?: { architecture?: string; os?: string; variant?: string }
  }>
}

type ManifestDetails = {
  created: string | null
  digest: string
  platforms: string[]
}

type Version = {
  major: number
  minor: number
  patch: number
  precision: number
  flavor: string
}

const manifestAccept = [
  "application/vnd.oci.image.index.v1+json",
  "application/vnd.oci.image.manifest.v1+json",
  "application/vnd.docker.distribution.manifest.list.v2+json",
  "application/vnd.docker.distribution.manifest.v2+json",
].join(", ")
const prerelease = /(?:^|[-_.])(alpha|beta|rc|preview|dev|nightly|edge|canary|main|master)(?:\d|$|[-_.])/i

function parseReference(reference: string, registry: Registry) {
  let value = reference.trim().replace(/^docker:\/\//, "")
  const at = value.indexOf("@")
  const suppliedDigest = at >= 0 ? value.slice(at + 1) : undefined
  if (at >= 0) value = value.slice(0, at)

  const parts = value.split("/")
  const host = parts.shift() ?? ""
  if (!registry.hosts.test(host)) throw new Error(`Unsupported ${registry.label} registry: ${host || "missing"}`)

  const last = parts.at(-1) ?? ""
  const colon = last.lastIndexOf(":")
  const tag = colon >= 0 ? last.slice(colon + 1) : suppliedDigest ? undefined : "latest"
  if (colon >= 0) parts[parts.length - 1] = last.slice(0, colon)
  if (parts.length < 2 || parts.some((part) => !part) || !tag && !suppliedDigest) {
    throw new Error(`Invalid ${registry.label} image reference: ${reference}`)
  }

  return { host, repository: parts.join("/"), tag, suppliedDigest }
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

function versionName(version: Version) {
  return `${version.major}.${version.minor}${version.patch >= 0 ? `.${version.patch}` : ""}`
}

function bearerChallenge(header: string | null) {
  if (!header?.match(/^Bearer /i)) return undefined
  return Object.fromEntries([...header.matchAll(/(\w+)="([^"]*)"/g)].map((match) => [match[1], match[2]]))
}

function nextLink(header: string | null, current: string) {
  const match = header?.match(/<([^>]+)>;\s*rel="?next"?/i)
  return match ? new URL(match[1], current).toString() : null
}

function platformName(platform: { architecture?: string; os?: string; variant?: string }) {
  if (!platform.os || !platform.architecture || platform.os === "unknown" || platform.architecture === "unknown") return undefined
  return `${platform.os}/${platform.architecture}${platform.variant ? `/${platform.variant}` : ""}`
}

function supportsPlatform(manifest: ManifestDetails, platform?: string) {
  return !platform || manifest.platforms.includes(platform)
}

export async function findOciRegistryVersions(
  input: { image: string; platform?: string },
  registry: Registry,
  signal?: AbortSignal,
) {
  const reference = parseReference(input.image, registry)
  const encodedRepository = reference.repository.split("/").map(encodeURIComponent).join("/")
  const root = `https://${reference.host}/v2/${encodedRepository}`
  let authorization: string | undefined

  const request = async (url: string, accept = "application/json") => {
    const headers: Record<string, string> = { Accept: accept }
    if (authorization) headers.Authorization = authorization
    let response = await fetch(url, { headers, signal })
    if (response.status === 401) {
      const challenge = bearerChallenge(response.headers.get("www-authenticate"))
      if (!challenge?.realm) throw new Error(`${registry.label} requires unsupported authentication for ${url}`)
      const tokenUrl = new URL(challenge.realm)
      if (challenge.service) tokenUrl.searchParams.set("service", challenge.service)
      tokenUrl.searchParams.set("scope", challenge.scope || `repository:${reference.repository}:pull`)
      const tokenResponse = await fetch(tokenUrl, { headers: { Accept: "application/json" }, signal })
      if (!tokenResponse.ok) throw new Error(`${registry.label} token service returned ${tokenResponse.status}`)
      const token = await tokenResponse.json() as { access_token?: string; token?: string }
      const credential = token.token ?? token.access_token
      if (!credential) throw new Error(`${registry.label} token service did not return a token`)
      authorization = `Bearer ${credential}`
      headers.Authorization = authorization
      response = await fetch(url, { headers, signal })
    }
    if (!response.ok) throw new Error(`${registry.label} returned ${response.status} for ${url}`)
    return response
  }

  const tags: string[] = []
  let next: string | null = `${root}/tags/list?n=100`
  let pagesFetched = 0
  while (next) {
    if (pagesFetched >= 100) throw new Error(`${registry.label} pagination exceeded 100 pages`)
    const response = await request(next)
    const page = await response.json() as { tags?: string[] | null }
    tags.push(...(page.tags ?? []))
    next = nextLink(response.headers.get("link"), next)
    pagesFetched++
  }

  const manifestCache = new Map<string, Promise<ManifestDetails>>()
  const skippedManifests = new Set<string>()
  const getManifest = (tagOrDigest: string) => {
    const cached = manifestCache.get(tagOrDigest)
    if (cached) return cached
    const pending = (async () => {
      const response = await request(`${root}/manifests/${encodeURIComponent(tagOrDigest)}`, manifestAccept)
      const manifest = await response.json() as Manifest
      const digest = response.headers.get("docker-content-digest") ?? (tagOrDigest.startsWith("sha256:") ? tagOrDigest : "")
      if (!digest) throw new Error(`${registry.label} did not return a manifest digest for ${tagOrDigest}`)
      if (manifest.manifests) {
        return {
          created: null,
          digest,
          platforms: [...new Set(manifest.manifests.map((item) => item.platform && platformName(item.platform)).filter(Boolean))] as string[],
        }
      }

      let created: string | null = null
      const platforms: string[] = []
      if (manifest.config?.digest) {
        const configResponse = await request(`${root}/blobs/${encodeURIComponent(manifest.config.digest)}`)
        const config = await configResponse.json() as { architecture?: string; created?: string; os?: string; variant?: string }
        created = config.created ?? null
        const platform = platformName(config)
        if (platform) platforms.push(platform)
      }
      return { created, digest, platforms }
    })()
    manifestCache.set(tagOrDigest, pending)
    return pending
  }
  const probeManifest = async (tag: string) => {
    try {
      return await getManifest(tag)
    } catch {
      skippedManifests.add(tag)
      return undefined
    }
  }

  const currentManifest = await getManifest(reference.tag ?? reference.suppliedDigest!)
  const suppliedDigestMatches = !reference.suppliedDigest || currentManifest.digest === reference.suppliedDigest
  let currentTag = reference.tag
  let currentVersion = currentTag ? parseVersion(currentTag) : undefined
  if (!currentVersion) {
    const aliases = await Promise.all(tags.map(async (tag) => ({ tag, manifest: await probeManifest(tag) })))
    const versions = aliases
      .filter((entry) => entry.manifest?.digest === currentManifest.digest)
      .map((entry) => ({ tag: entry.tag, version: parseVersion(entry.tag) }))
      .filter((entry): entry is { tag: string; version: Version } => Boolean(entry.version))
      .sort((left, right) => compareVersions(right.version, left.version))
    currentTag = versions[0]?.tag ?? currentTag
    currentVersion = versions[0]?.version
  }

  const source = `${root}/tags/list`
  if (!currentVersion) {
    return {
      image: `${reference.host}/${reference.repository}`,
      current: currentTag ?? reference.suppliedDigest,
      current_digest: currentManifest.digest,
      platform: input.platform ?? "unconstrained",
      candidates: null,
      recommendation: null,
      confidence: "low",
      caveats: [
        "Current tag does not expose a numeric version scheme",
        ...(skippedManifests.size ? [`Skipped ${skippedManifests.size} tags whose manifests were unavailable`] : []),
      ],
      pages_fetched: pagesFetched,
      source,
    }
  }

  const versions = tags
    .map((tag) => ({ tag, version: parseVersion(tag) }))
    .filter((entry): entry is { tag: string; version: Version } => Boolean(entry.version))
    .filter((entry) => entry.version.precision >= currentVersion.precision)
    .filter((entry) => compareVersions(entry.version, currentVersion) > 0)
    .sort((left, right) => compareVersions(right.version, left.version))

  const matchingFlavor = versions.filter((entry) => entry.version.flavor === currentVersion.flavor)
  const newest = async (predicate: (version: Version) => boolean) => {
    for (const entry of matchingFlavor.filter((candidate) => predicate(candidate.version))) {
      const manifest = await probeManifest(entry.tag)
      if (!manifest) continue
      if (supportsPlatform(manifest, input.platform)) {
        return { tag: entry.tag, digest: manifest.digest, pushed: manifest.created, platforms: manifest.platforms }
      }
    }
    return null
  }
  const [patch, minor, latest] = await Promise.all([
    newest((version) => version.major === currentVersion.major && version.minor === currentVersion.minor),
    newest((version) => version.major === currentVersion.major),
    newest(() => true),
  ])

  let migrationNotice = null
  if (currentVersion.flavor) {
    const exactFlavorVersion = latest ? parseVersion(latest.tag) ?? currentVersion : currentVersion
    const migrations = versions.filter((entry) =>
      entry.version.flavor !== currentVersion.flavor && compareVersions(entry.version, exactFlavorVersion) > 0,
    )
    for (const entry of migrations) {
      const manifest = await probeManifest(entry.tag)
      if (!manifest) continue
      if (!supportsPlatform(manifest, input.platform)) continue
      migrationNotice = {
        newer_versions_exist: true,
        newest_observed_version: versionName(entry.version),
        current_flavor_latest_pushed: latest?.pushed ?? currentManifest.created,
        requires_flavor_change: true,
        message: `The ${currentVersion.flavor} line ends at ${latest?.tag ?? currentTag}. Newer image versions were observed but require an explicit flavor migration.`,
        evidence: [{ tag: entry.tag, digest: manifest.digest, pushed: manifest.created }],
      }
      break
    }
  }

  return {
    image: `${reference.host}/${reference.repository}`,
    current: currentTag ?? reference.suppliedDigest,
    current_digest: reference.suppliedDigest ?? currentManifest.digest,
    current_tag_digest: currentManifest.digest,
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
      ...(skippedManifests.size ? [`Skipped ${skippedManifests.size} tags whose manifests were unavailable`] : []),
    ],
    pages_fetched: pagesFetched,
    source,
  }
}
