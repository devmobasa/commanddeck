.pragma library
.import "../../UiConstants.js" as Ui
.import "../../Protocol.js" as Protocol

function focusBoundary(root, forward) {
  if (forward) {
    root.part_settingsSearch.forceActiveFocus()
    return
  }
  let current = root.part_closeButton
  let last = root.part_closeButton
  for (let count = 0; count < 256; count++) {
    const next = current.nextItemInFocusChain(true)
    if (!next || next === root.part_closeButton || !root.containsFocusItem(next)) break
    last = next
    current = next
  }
  last.forceActiveFocus()
}

function containsFocusItem(root, item) {
  let current = item
  while (current) {
    if (current === root) return true
    current = current.parent
  }
  return false
}

// Qt's generic ScrollView does not scroll arbitrary focused controls into view.
// Keep keyboard navigation visible on every Settings page and nested editor.
function revealControl(root, item) {
  if (!root.visible || !item || !item.activeFocus || !containsFocusItem(root, item)) return
  for (let current = item.parent; current && current !== root; current = current.parent) {
    if (typeof current.contentY !== "number" || typeof current.contentHeight !== "number"
        || !current.contentItem || typeof current.returnToBounds !== "function") continue
    const point = item.mapToItem(current.contentItem, 0, 0)
    const bottom = point.y + item.height
    let position = current.contentY
    if (point.y < position) position = point.y
    else if (bottom > position + current.height) position = bottom - current.height
    current.contentY = Math.max(0, Math.min(position, current.contentHeight - current.height))
  }
}

// Walk visual order, ignoring hidden pages and non-tab controls.
function contentControls(parent) {
  const result = []
  const visit = item => {
    if (!item.visible || !item.enabled) return
    if (item.activeFocusOnTab) { result.push(item); return }
    for (const child of item.children || []) visit(child)
  }
  for (const child of parent.children || []) visit(child)
  return result
}
function firstContentControl(parent) { return contentControls(parent)[0] || null }
function lastContentControl(parent) {
  const controls = contentControls(parent)
  return controls.length > 0 ? controls[controls.length - 1] : null
}

// Home and End go to the top or bottom of the page: the first or last control
// takes focus and the page scrolls to its edge. On the rail they pick the first
// or last page. A text field keeps them for its cursor, except the empty
// Settings search, which scrolls the page and keeps typing focus; sliders, an
// open choice list and a recording shortcut keep them too. Returns whether the
// key was used.
function jumpToEdge(root, current, parts, toEnd) {
  if (!current) return false
  if (containsFocusItem(parts.rail, current)) {
    const pages = root.filteredPages || []
    if (pages.length === 0) return false
    root.showPage(pages[toEnd ? pages.length - 1 : 0].id)
    return true
  }
  if (containsFocusItem(parts.search, current)) {
    if (String(parts.search.text || "").length > 0) return false
    return scrollPageToEdge(parts.pages, toEnd)
  }
  const onPage = containsFocusItem(parts.pages, current)
  if (!onPage && current !== parts.close) return false
  if (onPage && keepsEdgeKeys(current)) return false
  const target = toEnd ? lastContentControl(parts.pages) : firstContentControl(parts.pages)
  if (target) target.forceActiveFocus()
  scrollPageToEdge(parts.pages, toEnd)
  return true
}

function keepsEdgeKeys(item) {
  for (let current = item; current; current = current.parent) {
    if (current.recording === true || current.preparing === true) return true
    if (current.popup && current.popup.visible === true) return true
    if (current.cursorPosition !== undefined && current.readOnly !== true) return true
    if (current.from !== undefined && current.to !== undefined && current.stepSize !== undefined) return true
    if (current.activeFocusOnTab) break
  }
  return false
}

// The shown page's outermost visible scroller.
function scrollPageToEdge(pages, toEnd) {
  const queue = [pages.children[pages.currentIndex]]
  while (queue.length > 0) {
    const item = queue.shift()
    if (!item || !item.visible) continue
    if (typeof item.contentY === "number" && typeof item.contentHeight === "number"
        && typeof item.returnToBounds === "function" && item.height > 0) {
      const top = item.originY || 0
      item.contentY = toEnd ? top + Math.max(0, item.contentHeight - item.height) : top
      return true
    }
    for (const child of item.contentItem ? [item.contentItem] : item.children || []) queue.push(child)
  }
  return false
}
