pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "./components/Protocol.js" as Protocol
import "./components/Settings/SettingsSearchTarget.js" as SearchTarget
import "./DemoData.js" as Data
import "./ShowcaseTimeline.js" as Timeline

DemoStage {
  id: tour
  readonly property string scene: Quickshell.env("COMMANDDECK_GALLERY_SCENE")
  readonly property bool captions: scene.endsWith("-captions")
  readonly property string feature: scene.slice("showcase-".length, scene.lastIndexOf("-"))
  property bool cardVisible: false
  property bool titleCard: false
  property string heading: ""
  property string detail: ""
  property string number: ""
  property real cardInk: 1
  property var spotlightTarget: null
  property var pressedControl: null
  property var baseSnapshot: null
  filters: Data.filters
  defaultCaption: ""
  shots: Timeline.build(feature, captions, tour)

  Component.onCompleted: {
    tour.panel.width = 1224
    tour.panel.height = 758
    tour.panel.requestedWidth = 1224
    tour.panel.requestedHeight = 758
    tour.panel.anchors.verticalCenterOffset = -24
    tour.theme.displayScale = 1.3
    tour.theme.textScale = 1.3
    tour.baseSnapshot = JSON.parse(JSON.stringify(settings.snapshot))
    const model = tour.baseSnapshot.shortcutEditor
    model.bindings.push({id: "menu", chord: "Super+Q", description: "Omarchy menu", changeable: true})
    model.bindings.push({id: "obsidian", chord: "Super+Shift+O", description: "Obsidian", changeable: true})
    tour.baseSnapshot.preferences.searchHomeOnly = false
    settings.fallbackQuicklinks = [{id: "web", title: "Web search"}, {id: "docs", title: "Team docs"}]
    settings.snapshot = JSON.parse(JSON.stringify(tour.baseSnapshot))
  }
  panelOverlays: [
    DemoSettings {
      id: settings
      galleryStage: tour
      anchors.fill: parent
      // A fictional server receipt updates only the gallery's in-memory snapshot.
      onPreferencesChanged: value => {
        const copy = JSON.parse(JSON.stringify(snapshot))
        copy.preferences = value
        snapshot = copy
      }
    }
  ]
  ShowcaseCard {
    id: cards
    anchors.fill: parent
    visible: tour.cardVisible || tour.captions
    captionMode: !tour.cardVisible
    titleCard: tour.titleCard
    heading: tour.heading
    detail: tour.detail
    number: tour.number
    inkOpacity: tour.cardInk
  }
  // A small press halo guides the eye without a fake desktop cursor.
  Rectangle {
    visible: !!tour.pressedControl && !tour.cardVisible
    readonly property point position: tour.pressedControl
      ? tour.pressedControl.mapToItem(parent, tour.pressedControl.width - 18, tour.pressedControl.height / 2) : Qt.point(0, 0)
    x: position.x - 14
    y: position.y - 14
    width: 28
    height: 28
    radius: 14
    color: "#405b9cf5"
    border.width: 2
    border.color: "#5b9cf5"
  }
  onShotSaved: {
    if (!cards.fits()) tour.fail("The card or caption does not fit")
    if (!tour.cardVisible && settings.visible && !tour.contained(settings.closeControl)) tour.fail("Clipped Settings frame")
    const check = tour.shots[tour.shotIndex].expect
    if (check) tour.verifyBeat(check)
  }

  function fail(message) { console.error("Showcase: " + message); Qt.exit(1) }
  function row(id) {
    const items = settings.parts.shortcutsScroll.desktopRepeater
    for (let n = 0; n < items.count; n++) if (items.itemAt(n).binding.id === id) return items.itemAt(n)
    return null
  }
  function control(text, parent) {
    const node = parent || settings
    if (node.text === text || node.label === text) return node
    for (const child of node.children || []) {
      const match = control(text, child)
      if (match) return match
    }
    return null
  }
  function viewport() {
    const key = settings.currentPage + "Scroll"
    const page = settings.parts[key]
    return page ? page.contentItem : null
  }
  function page(id) {
    settings.searchControl.text = ""
    settings.showPage(id)
    tour.deck.settingsOpen = true
    Qt.callLater(() => { const view = viewport(); if (view) view.contentY = 0 })
  }
  function showLauncher() {
    settings.shortcutController.cancelRecording()
    tour.deck.settingsOpen = false
    tour.setResults("", [], "Search")
    tour.content.part_searchBar.inputControl.forceActiveFocus()
  }
  function setEditor(change) {
    const model = JSON.parse(JSON.stringify(settings.snapshot.shortcutEditor))
    change(model)
    const snap = JSON.parse(JSON.stringify(settings.snapshot))
    snap.shortcutEditor = model
    settings.snapshot = snap
    settings.shortcutController.snapshot = model
  }
  function spot(alpha) {
    const dim = settings.parts.spotlight
    const target = tour.spotlightTarget || settings.searchTarget
    if (!target) return tour.fail("Missing spotlight target")
    dim.dismiss()
    dim.scrollIntoView(target)
    Qt.callLater(() => {
      dim.dismiss()
      const point = target.mapToItem(dim, 0, 0)
      dim.area = Qt.rect(point.x, point.y, target.width, target.height)
      dim.target = target
      dim.opacity = alpha
    })
  }
  function act(action, args) {
    if (action.indexOf("press") !== 0) {
      if (tour.pressedControl) tour.pressedControl.down = false
      tour.pressedControl = null
    }
    if (action === "card") {
      settings.shortcutController.cancelRecording()
      tour.cardVisible = true
      tour.heading = args[0]; tour.detail = args[1]; tour.number = args[2]
      tour.titleCard = args[3]; tour.cardInk = args[4]
    } else if (action === "clip") {
      tour.cardVisible = false
      tour.detail = args[0]; tour.heading = args[1]
    } else if (action === "shortcuts") {
      settings.show("shortcuts")
    } else if (action === "filterKeys") settings.parts.shortcutsScroll.part_keybindingSearch.text = args[0]
    else if (action === "prepare") {
      settings.preparingShot = true
      row("balance").pill.startRecording()
    } else if (action === "record") {
      settings.preparingShot = false
      const controller = settings.shortcutController
      controller.handleMessage({requestId: controller.active.requestId, type: Protocol.Messages.Done})
    } else if (action === "conflict") {
      row("balance").pill.cancelRecording()
      settings.shortcutController.conflict = {operation: Protocol.Operations.ShortcutSet,
        shortcut: {id: "balance", chord: "Super+Q"}, description: "Omarchy menu"}
    } else if (action === "pressReplace") press(control("Replace", row("balance")))
    else if (action === "replace") {
      control("Replace", row("balance")).clicked()
      setEditor(model => {
        model.changeCount = 3
        model.bindings = model.bindings.map(value => value.id === "balance"
          ? Object.assign({}, value, {chord: "Super+Q", changed: true, originalChord: ""})
          : value.id === "menu" ? Object.assign({}, value, {chord: "", changed: true, originalChord: "Super+Q"}) : value)
      })
    } else if (action === "pressRestore") press(row("balance").restoreControl)
    else if (action === "restore") {
      row("balance").restoreControl.clicked()
      setEditor(model => {
        model.changeCount = 1
        model.bindings = model.bindings.map(value => value.id === "balance"
          ? Object.assign({}, value, {chord: "", changed: false})
          : value.id === "menu" ? Object.assign({}, value, {chord: "Super+Q", changed: false}) : value)
      })
    } else if (action === "menu") settings.parts.shortcutsScroll.moreMenu.open()
    else if (action === "closeMenu") settings.parts.shortcutsScroll.moreMenu.close()
    else if (action === "launcher") showLauncher()
    else if (action === "appQuery") {
      const app = Data.app(tour.icon("obsidian"), "obsidian", "Obsidian", "Your notes, connected", "obsidian", Data.section("applications", "Applications", 1))
      app.metadata = {keybinding: "Super+Shift+O"}
      // The real row's order: Ctrl+Enter stays Open New Window, Alt+K changes the key.
      app.actions.push({id: "launch-new", title: "Open New Window", kind: Protocol.ActionKinds.LaunchDesktop,
        arguments: {newInstance: "true"}})
      app.actions.push({id: "copy-hyprland-binding", title: "Copy Hyprland Binding", kind: Protocol.ActionKinds.CopyText,
        arguments: {}})
      app.actions.push({id: "change-shortcut", title: "Change Shortcut…", kind: Protocol.ActionKinds.OpenSettings,
        arguments: {settingId: Protocol.SettingIds.DesktopShortcuts}})
      tour.setResults(args[0], [app], "1 application")
    } else if (action === "rebind") {
      settings.preparingShot = false
      tour.deck.settingsOpen = true
      settings.recordShortcut({description: "Obsidian", chord: "Super+Shift+O"})
      Qt.callLater(() => settings.parts.spotlight.scrollIntoView(row("obsidian")))
    } else if (action === "settingQuery") {
      tour.setResults(args[0], [{id: "setting:reduce-motion", kind: Protocol.ResultKinds.Setting, title: "Reduce motion",
        subtitle: "Settings › Search", icon: tour.icon("preferences-system"), section: Data.section("settings", "Settings", 1),
        actions: [{id: "open", title: "Open setting", kind: Protocol.ActionKinds.OpenSettings,
          arguments: {settingId: Protocol.SettingIds.SearchBehavior}}]}], "1 setting")
    } else if (action === "revealMotion") {
      page("search")
      settings.revealSetting(Protocol.SettingIds.SearchBehavior)
      Qt.callLater(() => {
        tour.spotlightTarget = settings.settingCard(Protocol.SettingIds.SearchBehavior)
        settings.parts.spotlight.dismiss()
      })
    } else if (action === "spotlight") spot(args[0])
    else if (action === "clearSearch") { tour.spotlightTarget = null; settings.searchControl.forceActiveFocus() }
    else if (action === "settingsQuery") {
      settings.searchControl.text = args[0]
      settings.parts.spotlight.dismiss()
    } else if (action === "focusTarget") {
      settings.parts.spotlight.dismiss()
      settings.searchControl.accepted()
      Qt.callLater(() => settings.parts.spotlight.dismiss())
    } else if (action === "longPage") { page("customization"); settings.closeControl.forceActiveFocus() }
    else if (action === "end" || action === "home") settings.jumpToEdge(action === "end")
    else if (action === "page") page(args[0])
    else if (action === "searchRows") {
      page("search")
      Qt.callLater(() => settings.parts.spotlight.scrollIntoView(settings.part_behaviorCard))
    } else if (action === "popup") settings.parts.searchScroll.part_fallbackChoice.popup.open()
    else if (action === "pressSwitch") {
      settings.parts.searchScroll.part_fallbackChoice.popup.close()
      press(control("Inline calculator"))
    } else if (action === "flipSwitch") control("Inline calculator").click()
    else if (action === "segments") page("editors")
    else if (action === "font") {
      page("customization")
      settings.part_interfaceFont.select(args[0] === "shell" ? 1 : 0)
    } else if (action === "diagnostics") {
      tour.theme.displayScale = 1.2
      tour.theme.textScale = 1.2
      page("diagnostics")
    } else if (action === "pressCopy") press(settings.parts.diagnosticsScroll.part_copyReportButton)
    else if (action === "copied") {
      // Demonstrate the receipt without copying even to an offscreen clipboard.
      settings.parts.diagnosticsScroll.copiedLabel = "report"
    }
  }
  function press(item) {
    if (!item) return fail("Missing press target")
    tour.pressedControl = item
    item.down = true
  }
  function contained(item) {
    if (!item || !item.visible || item.width <= 0 || item.height <= 0) return false
    for (let parent = item.parent; parent; parent = parent.parent) {
      if (!parent.clip && parent !== settings) continue
      const point = item.mapToItem(parent, 0, 0)
      if (point.x < -2 || point.y < -2 || point.x + item.width > parent.width + 2 || point.y + item.height > parent.height + 2) return false
    }
    return true
  }
  function verifyBeat(check) {
    let good = true
    if (check === "preparing") good = row("balance").pill.preparing && !row("balance").pill.recording
    if (check === "key-filter") good = settings.parts.shortcutsScroll.keybindingMatches.rows.length === 1 && row("menu").visible
    if (check === "key-hint") good = tour.deck.part_navigation.selectedResult().metadata.keybinding === "Super+Shift+O"
    if (check === "outlined") good = !!settings.searchTarget && contained(settings.searchTarget)
    if (check === "recording") good = row("balance").pill.recording && contained(row("balance").pill)
    if (check === "conflict") good = row("balance").hasConflict && contained(control("Replace", row("balance")))
    if (check === "changed") good = row("balance").binding.changed && row("balance").pill.chord === "Super+Q"
    if (check === "restored") good = !row("balance").binding.changed && !row("balance").pill.chord
    if (check === "menu") good = settings.parts.shortcutsScroll.moreMenu.visible
    if (check === "obsidian-recording") good = row("obsidian").pill.recording && contained(row("obsidian").pill)
    if (check === "focused") good = !!settings.searchTarget && SearchTarget.focusItem(settings.searchTarget).activeFocus
    if (check === "bottom") good = viewport().contentY > 0 && Math.abs(viewport().contentY + viewport().height - viewport().contentHeight) < 3
    if (check === "top") good = viewport().contentY === 0
    if (check === "switch") good = control("Inline calculator").checked
    if (check === "shell-font") good = settings.interfaceFont === "shell" && tour.theme.fontFamily === tour.theme.monoFontFamily
    if (check === "copied") good = settings.parts.diagnosticsScroll.part_copyReportButton.text === "Copied" && contained(settings.parts.diagnosticsScroll.part_copyReportButton)
    if (!good) fail("Wrong or clipped state: " + check + (check === "obsidian-recording" ? " recording=" + row("obsidian").pill.recording + " preparing=" + row("obsidian").pill.preparing + " contained=" + contained(row("obsidian").pill) : ""))
  }
}
