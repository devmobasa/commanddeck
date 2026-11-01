.pragma library

// Each QML engine resolves installed proportional fonts only on first use.
var cachedSansFamily = ""
function sansFamily() {
  if (cachedSansFamily.length > 0) return cachedSansFamily
  const installed = Qt.fontFamilies()
  const preferred = ["Adwaita Sans", "Inter", "Noto Sans", "Cantarell", "IBM Plex Sans"]
  cachedSansFamily = preferred.find(family => installed.indexOf(family) >= 0) || "sans-serif"
  return cachedSansFamily
}
