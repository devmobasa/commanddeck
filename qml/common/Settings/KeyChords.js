.pragma library

// Chords as the daemon spells Hyprland bindings: Super, Ctrl, Alt, Shift, then
// the key. Comparison ignores case, so "super+b" finds "Super+B".
var ModifierOrder = ["super", "ctrl", "alt", "shift"]
var ModifierNames = { super: "super", win: "super", meta: "super", mod: "super", mod4: "super", cmd: "super", logo: "super",
  ctrl: "ctrl", control: "ctrl", alt: "alt", option: "alt", shift: "shift" }
var KeyNames = { "return": "enter", enter: "enter", esc: "escape", escape: "escape", space: "space" }

// "super+space", "Ctrl K", and "shift super b" are chords. Text needs at least
// one modifier and exactly one key; anything else searches descriptions.
function parse(text) {
  const words = String(text || "").trim().toLowerCase().split(/[\s+]+/).filter(word => word.length > 0)
  const modifiers = []
  let key = ""
  for (const word of words) {
    const modifier = ModifierNames[word]
    if (modifier) {
      if (modifiers.indexOf(modifier) < 0) modifiers.push(modifier)
    } else if (key.length === 0) {
      key = KeyNames[word] || word
    } else {
      return ""
    }
  }
  if (key.length === 0) return ""
  if (modifiers.length === 0 && !/^(f([1-9]|1[0-9]|2[0-4])|xf86[a-z0-9]+)$/.test(key)) return ""
  return ModifierOrder.filter(modifier => modifiers.indexOf(modifier) >= 0).concat([key]).join("+")
}

// Bindings on a chord, or whose description or chord contains the text.
function search(bindings, text) {
  const needle = String(text || "").trim().toLowerCase()
  const chord = parse(needle)
  if (needle.length === 0) return { chord: "", rows: [] }
  const rows = (bindings || []).filter(binding => chord.length > 0
    ? (parse(binding.chord) || String(binding.chord).toLowerCase()) === chord
    : String(binding.description).toLowerCase().indexOf(needle) >= 0 || String(binding.chord).toLowerCase().indexOf(needle) >= 0)
  return { chord: chord, rows: rows }
}

// How many top-level bindings share each chord; more than one is a conflict.
function sharedCounts(bindings) {
  const counts = ({})
  for (const binding of bindings || []) {
    if (binding.submap) continue
    const chord = parse(binding.chord) || String(binding.chord).toLowerCase()
    counts[chord] = (counts[chord] || 0) + 1
  }
  return counts
}

function heading(found, text) {
  const count = found.rows.length
  if (found.chord.length > 0) {
    const shown = count > 0 ? found.rows[0].chord : String(text).trim()
    if (count === 0) return "Nothing is bound to " + shown + "."
    if (count === 1) return shown + " runs one binding."
    return shown + ": " + count + " bindings share this key. Hyprland runs all of them."
  }
  if (count === 0) return "No binding matches."
  return count === 1 ? "1 binding" : count + " bindings"
}

// Display the same normalized modifier order used by Settings search.
function display(text) {
  const parsed = parse(text)
  if (!parsed) return String(text || "")
  const names = { super: "Super", ctrl: "Ctrl", alt: "Alt", shift: "Shift", enter: "Enter", escape: "Esc", space: "Space" }
  return parsed.split("+").map(part => names[part] || (part.indexOf("xf86") === 0 ? String(text).split(/[+\s]+/).find(value => value.toLowerCase() === part) || part : part.toUpperCase())).join("+")
}
