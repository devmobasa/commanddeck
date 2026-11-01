.pragma library
.import "../Protocol.js" as Protocol

// What a dragged row offers other apps: the same text/uri-list a file manager
// sends, for any row that opens a path.
function filePath(result) {
  const open = result ? (result.actions || []).find(action => action.kind === Protocol.ActionKinds.OpenPath) : null
  return open && open.arguments ? String(open.arguments.path || "") : ""
}

function fileUri(path) {
  return "file://" + String(path).split("/").map(encodeURIComponent).join("/")
}

function mimeData(path) {
  return path ? { "text/uri-list": fileUri(path) + "\r\n", "text/plain": path } : ({})
}
