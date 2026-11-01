.pragma library

// The Diagnostics page's rows, built from the daemon's status reply. Each value
// is plain text so one Copy button, or Copy debug info, can take it as shown.
function rows(status) {
  if (!status) return []
  const catalog = status.catalog || {}
  const indexing = status.indexing || {}
  const timings = status.searchTimings || {}
  const list = [
    { label: "Version", value: status.version || "Unknown" },
    { label: "Process", value: status.processId ? String(status.processId) : "Unknown" },
    { label: "Started", value: status.startedAt ? String(status.startedAt).replace("T", " ").slice(0, 19) : "Unknown" },
    { label: "Socket", value: status.socketPath || "Unknown" },
    { label: "Catalog", value: count(catalog.itemCount) + " items: " + count(catalog.fileCount) + " files, "
      + count(catalog.configCount) + " configuration, " + count(catalog.applicationCount) + " applications" },
    { label: "Database", value: size(catalog.databaseBytes) },
    { label: "Index", value: count(indexing.watchedRootCount) + " watched folders, " + count(indexing.pendingEventCount) + " pending changes" },
    { label: "Searches", value: timings.searches > 0
      ? "Last " + timings.searches + ": median " + timings.medianMilliseconds + " ms, p95 " + timings.p95Milliseconds
        + " ms, slowest " + timings.maximumMilliseconds + " ms"
      : "No searches yet" }
  ]

  // The slowest providers first; a deadline it keeps missing is named.
  for (const provider of (timings.providers || []).slice(0, 5)) {
    list.push({ label: "Provider " + provider.id, value: "p95 " + provider.p95Milliseconds + " ms, slowest " + provider.maximumMilliseconds + " ms"
      + (provider.timeouts > 0 ? ", " + provider.timeouts + " of " + provider.runs + " timed out" : "") })
  }

  for (const health of status.providers || []) {
    if (health.state === "available") continue
    list.push({ label: health.label, value: health.state + (health.detail ? ": " + health.detail : "") })
  }
  return list
}

function report(rows) {
  return rows.map(row => row.label + ": " + row.value).join("\n")
}

function count(value) {
  return String(Number(value) || 0)
}

function size(bytes) {
  const value = Number(bytes) || 0
  if (value >= 1024 * 1024) return (value / (1024 * 1024)).toFixed(1) + " MiB"
  if (value >= 1024) return (value / 1024).toFixed(1) + " KiB"
  return value + " bytes"
}
