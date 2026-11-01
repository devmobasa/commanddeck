.pragma library

// Tab and Shift+Tab stay inside a dialog that declares `settingsTabFence`:
// the nearest such ancestor of `start` decides where focus goes next, through
// its cycleFocus(forward). Without one the key is left to Qt's focus chain.
// Home and End go to the fence's jumpToEdge(toEnd) when it has one; it returns
// false to leave them to the focused control, such as a text cursor.
// Returns whether the key was handled.
function route(start, event) {
  const edge = (event.key === Qt.Key_Home || event.key === Qt.Key_End) && (event.modifiers & ~Qt.KeypadModifier) === 0
  if (event.key !== Qt.Key_Tab && event.key !== Qt.Key_Backtab && !edge) return false

  let fence = start
  while (fence && fence.settingsTabFence !== true) fence = fence.parent
  if (!fence) return false

  if (edge) {
    if (typeof fence.jumpToEdge !== "function" || !fence.jumpToEdge(event.key === Qt.Key_End)) return false
    event.accepted = true
    return true
  }

  fence.cycleFocus(event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))
  event.accepted = true
  return true
}
