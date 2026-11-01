.pragma library

// Points Settings search at one control: a switch, checkbox, button, or
// labelled row. Each word scores 2 where it starts a word of the label, 1
// elsewhere in the label, and a little in the help; a word found nowhere rules
// the control out. The highest score wins; earlier on the page breaks a tie.
// A card that matches only by its title or index words (Transparency, whose
// switch is "Transparent background") points at its first control, below any
// real control match.
const CardMatchScore = 0.1

// The best control on any page, and the page that holds it. Pages other than
// the shown one are hidden, so only their cards' search match is checked.
function best(pages, pageCards, currentPage, query) {
  const terms = words(query)
  let found = { control: null, page: "", score: 0 }
  if (terms.length === 0) return found
  for (const page of pages || []) {
    const shown = page.id === currentPage
    for (const card of pageCards[page.id] || []) {
      if (!card || !card.matchesSearch || shown && !card.visible) continue
      const candidate = search(card, terms, shown)
      if (candidate.score > found.score) found = { control: candidate.control, page: page.id, score: candidate.score }
    }
  }
  return found
}

// The best visible control among the shown page's cards.
function find(cards, query) {
  const terms = words(query)
  let found = { control: null, score: 0 }
  if (terms.length === 0) return null
  for (const card of cards || []) {
    if (!card || !card.visible) continue
    const candidate = search(card, terms, true)
    if (candidate.score > found.score) found = candidate
  }
  return found.control
}

function words(query) {
  return String(query || "").toLowerCase().trim().split(/\s+/).filter(term => term.length > 0)
}

function search(root, terms, respectVisibility) {
  let found = { control: null, score: 0 }
  let first = null
  const visit = node => {
    if (!node || respectVisibility && node.visible === false) return
    if (isControl(node)) {
      if (!first) first = node
      const value = score(node, terms)
      if (value > found.score) found = { control: node, score: value }
    }
    const children = node.children || []
    for (let index = 0; index < children.length; index++) visit(children[index])
  }
  visit(root)
  // Callers pass only cards that match the search.
  return found.control || !first ? found : { control: first, score: CardMatchScore }
}

function score(node, terms) {
  const label = String(node.label !== undefined ? node.label : node.text).toLowerCase()
  const help = String(node.help || "").toLowerCase()
  let total = 0
  for (const term of terms) {
    if (startsWord(label, term)) total += 2
    else if (label.indexOf(term) >= 0) total += 1
    else if (help.indexOf(term) >= 0) total += 0.25
    else return 0
  }
  return total
}

function startsWord(text, term) {
  for (let at = text.indexOf(term); at >= 0; at = text.indexOf(term, at + 1)) {
    if (at === 0 || !/[a-z0-9]/.test(text.charAt(at - 1))) return true
  }
  return false
}

// Rows carry a label and help; switches, checkboxes, and buttons carry text.
function isControl(node) {
  return typeof node.label === "string" && typeof node.help === "string"
    || node.checkable !== undefined && typeof node.text === "string" && node.text.length > 0
}

// The item that takes the keyboard for a control: itself, or the first
// focusable item inside a row.
function focusItem(control) {
  if (!control) return null
  if (control.activeFocusOnTab) return control
  const children = control.children || []
  for (let index = 0; index < children.length; index++) {
    const child = children[index]
    if (!child || child.visible === false || child.enabled === false) continue
    const inner = focusItem(child)
    if (inner) return inner
  }
  return null
}
