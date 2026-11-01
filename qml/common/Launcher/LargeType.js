.pragma library
.import "../Protocol.js" as Protocol

// What Ctrl+L shows: a calculator answer, then the typed text, then the
// selected row's title. Nothing to show leaves the launcher as it is.
function textFor(query, result) {
  if (result && result.kind === Protocol.ResultKinds.Calculator) return String(result.title || "")
  const typed = String(query || "").trim()
  return typed.length > 0 ? typed : result ? String(result.title || "") : ""
}
