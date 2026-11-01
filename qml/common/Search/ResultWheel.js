.pragma library

// A mouse wheel moves the result list one row per notch, and section headers
// come along with the row under them. Touchpads keep scrolling by pixels.
const NotchAngle = 120

// A real wheel turn: whole notches, or a hi-res wheel that reports no pixels.
// Notched wheels report pixels too, so pixels alone cannot spot a touchpad.
function isWheelTurn(idlePhase, angle, pixels) {
  return idlePhase && angle !== 0 && (angle % NotchAngle === 0 || pixels === 0)
}

// Whole notches in the turn so far; a part-notch carries to the next event.
function notches(angle, carried) {
  const total = carried + angle
  const steps = Math.trunc(total / NotchAngle)
  return { steps: steps, remainder: total - steps * NotchAngle }
}

function nextRow(index, direction, count, isHeader) {
  for (let row = index + direction; row >= 0 && row < count; row += direction) {
    if (!isHeader(row)) return row
  }
  return -1
}

// The result row `steps` rows from the top one; stops at the ends of the list.
function targetRow(top, steps, count, isHeader) {
  const first = isHeader(top) ? nextRow(top, 1, count, isHeader) : top
  let target = first < 0 ? top : first
  const direction = steps > 0 ? 1 : -1
  for (let remaining = Math.abs(steps); remaining > 0; remaining--) {
    const next = nextRow(target, direction, count, isHeader)
    if (next < 0) break
    target = next
  }
  return target
}
