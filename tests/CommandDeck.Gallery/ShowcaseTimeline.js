.pragma library

// One sequence of UI beats feeds both edits. Hold times are encoded in filenames,
// independent of renderer speed; short settles only allow Qt to lay out each shot.
function build(kind, captions, host) {
  const steps = []
  let pendingClip = null
  const add = (hold, action, args, check) => {
    steps.push({hold: hold, action: action, args: args, check: check, clip: pendingClip})
    pendingClip = null
  }
  const card = (title, detail, number, titleCard) => {
    for (const opacity of [0, 0.34, 0.72]) add(50, "card", [title, detail, number, titleCard, opacity])
    add(titleCard ? 1900 : 1000, "card", [title, detail, number, titleCard, 1])
    for (const opacity of [0.72, 0.34, 0]) add(50, "card", [title, detail, number, titleCard, opacity])
  }
  let chapter = 0
  const total = kind === "new-look" ? 4 : 6
  const beat = (key, title) => {
    chapter++
    if (!captions) card(title, key, chapter + " / " + total, false)
    pendingClip = [key, title]
  }
  const type = (text, action, hold, check) => {
    for (let n = 1; n <= text.length; n++) add(n === text.length ? hold : 80, action, [text.slice(0, n)], n === text.length ? check : null)
  }
  const spot = (action) => {
    for (const alpha of [0.25, 0.65, 1]) add(50, action, [alpha])
    add(1400, action, [1])
    for (const alpha of [0.65, 0.25, 0]) add(50, action, [alpha])
  }
  const titles = {
    shortcuts: ["Change any shortcut", "Rebind Hyprland keys from Settings or from search"],
    "settings-search": ["Settings, found", "Search from the launcher or inside Settings and land on the control"],
    "new-look": ["A calmer Settings", "Grouped rows, small controls, and your choice of font"]
  }
  if (!captions) card(titles[kind][0], titles[kind][1], "", true)
  if (kind === "shortcuts") {
    beat("Ctrl+,", "Every key in one place")
    add(2200, "shortcuts")
    beat("super+q", "Find what a key does")
    type("super+q", "filterKeys", 1800, "key-filter")
    beat("Click", "Press the new keys")
    add(900, "filterKeys", [""])
    add(450, "prepare", [], "preparing")
    add(1300, "record", [], "recording")
    add(900, "conflict", [], "conflict")
    beat("Replace", "Taken? You choose")
    add(1000, "noop", [], "conflict")
    add(160, "pressReplace")
    add(1900, "replace", [], "changed")
    beat("↺", "Undo any change")
    add(160, "pressRestore")
    add(1200, "restore", [], "restored")
    add(1600, "menu", [], "menu")
    add(300, "closeMenu")
    beat("Alt+K", "Rebind from search")
    add(900, "launcher")
    type("obsidian", "appQuery", 1600, "key-hint")
    add(1700, "rebind", [], "obsidian-recording")
  } else if (kind === "settings-search") {
    beat("reduce motion", "Settings are searchable")
    add(900, "launcher")
    type("reduce motion", "settingQuery", 1600)
    beat("Enter", "Opens right at the control")
    add(900, "revealMotion")
    spot("spotlight")
    beat("transparency", "Search inside Settings")
    add(900, "clearSearch")
    type("transparency", "settingsQuery", 1300, "outlined")
    beat("…pause", "Stop typing, it lights up")
    spot("spotlight")
    add(900, "noop")
    beat("Enter", "Go straight to it")
    add(2100, "focusTarget", [], "focused")
    beat("Home / End", "Top and bottom")
    add(1300, "longPage")
    add(1900, "end", [], "bottom")
    add(1900, "home", [], "top")
  } else {
    beat("Ctrl+,", "Pages in groups")
    for (const page of ["search", "ai", "editors", "shortcuts", "customization"]) add(1000, "page", [page])
    beat("Rows", "Calm, compact controls")
    add(1400, "searchRows")
    add(1600, "popup")
    add(160, "pressSwitch")
    add(1400, "flipSwitch", [], "switch")
    add(1400, "segments")
    beat("Sans ↔ Shell font", "One switch, the whole interface")
    add(1600, "font", ["sans"])
    add(2000, "font", ["shell"], "shell-font")
    add(1600, "font", ["sans"])
    beat("Diagnostics", "Everything in one place")
    add(1600, "diagnostics")
    add(160, "pressCopy")
    add(1900, "copied", [], "copied")
  }
  return steps.map((step, index) => ({
    name: "frame-" + String(index + 1).padStart(4, "0") + "-" + String(step.hold).padStart(5, "0") + ".png",
    frame: {width: 1280, height: 900}, caption: "", settle: 100,
    show: () => {
      if (step.clip) host.act("clip", step.clip)
      host.act(step.action, step.args || [])
    }, expect: step.check
  }))
}
