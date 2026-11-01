pragma ComponentBehavior: Bound
import QtQuick
import "./components/Protocol.js" as Protocol
import "./components" as Deck
import "./DemoData.js" as Data

// The real Settings pages with prepared data and no protocol connection.
Deck.SettingsPanel {
  id: settings
  required property var galleryStage
  theme: galleryStage.theme
  insetFrame: galleryStage.panel.frameInset > 0
  shortcutController: shortcutsDemo
  property int shortcutSequence: 0
  property bool preparingShot: false
  Deck.ShortcutEditorController {
    id: shortcutsDemo
    nextRequestId: () => ++settings.shortcutSequence
    onRequest: value => {
      if (value.operation !== Protocol.Operations.ShortcutRecordStart || !settings.preparingShot)
        Qt.callLater(() => shortcutsDemo.handleMessage({requestId: value.requestId, type: Protocol.Messages.Done}))
    }
  }
  visible: galleryStage.deck.settingsOpen
  sourceDescriptors: [
    { id: "applications", label: "Applications", icon: "applications-other" },
    { id: "files", label: "Files", icon: "folder" }
  ]
  snapshot: ({ shortcutEditor: {
    moduleInstalled: true, hotkeyManaged: true, hotkey: "Ctrl+Space", changeCount: 1,
    configurationPath: "/fictional/hypr/commanddeck_keys.lua",
    bindings: [
      { id: "terminal", chord: "Super+Return", description: "Open Terminal", changeable: true },
      { id: "balance", chord: "", description: "Balance splits", changeable: true },
      { id: "screenshot", chord: "Super+Shift+S", originalChord: "Super+S", description: "Screenshot", changeable: true, changed: true },
      { id: "workspace", chord: "Super+1", description: "Open workspace 1", changeable: false,
        reason: "This binding is built by your Hyprland configuration (for example in a loop). Change it in /fictional/hypr/bindings.lua.", sourceFile: "/fictional/hypr/bindings.lua" }
    ]
  }, preferences: {
    sources: [
      { sourceId: "applications", enabledInSearch: true, enabledOnHome: true, position: 1 },
      { sourceId: "files", enabledInSearch: true, enabledOnHome: true, position: 2 }
    ], reduceMotion: true, rememberSearches: true, learnFromUse: true,
    topMatches: true, hideAfterAction: true, omarchyMenuState: true, workspacePreviewMode: Protocol.WorkspacePreviewModes.Layout
  }, customizations: [], shortcuts: [
    { label: "Open CommandDeck", chords: ["Super+Space"], status: "configured", detail: "Desktop binding" },
    { label: "Open Terminal", chords: ["Super+Return"], status: "configured", detail: "Desktop binding" },
    { label: "Quick answer", chords: [], status: "not-configured", detail: "No desktop binding" }
  ], keybindings: [
    { chord: "Super+Space", description: "Open CommandDeck", submap: "" },
    { chord: "Super+Return", description: "Open Terminal", submap: "" }
  ] })
  runtimeStatus: ({
    version: "0.1.0-preview", processId: 2081, startedAt: "2026-10-29T08:16:02Z",
    socketPath: "/run/user/1000/commanddeck.sock",
    catalog: { itemCount: 22089, fileCount: 3579, configCount: 18090, applicationCount: 87, databaseBytes: 69488640 },
    indexing: { watchedRootCount: 2, pendingEventCount: 0 },
    searchTimings: { searches: 258, medianMilliseconds: 23, p95Milliseconds: 91, maximumMilliseconds: 352,
      providers: [{ id: "catalog", runs: 120, p95Milliseconds: 182, maximumMilliseconds: 350, timeouts: 3 }] },
    providers: []
  })
  indexRoots: Data.indexRoots()
  quicklinksController: links
  interfaceFont: galleryStage.deck.interfaceFont
  onInterfaceFontSelected: choice => galleryStage.deck.applyInterfaceFont(choice)
  displaySizePercent: galleryStage.deck.displaySizePercent
  maximumFittingPercent: galleryStage.content.host.maximumFittingPercent
  displaySizeDescription: galleryStage.content.host.displayDescription
  launcherWidthPercent: galleryStage.deck.launcherWidthPercent
  launcherHeightPercent: galleryStage.deck.launcherHeightPercent

  Deck.QuicklinksController {
    id: links
    ready: false
    nextRequestId: () => 1
    quicklinks: Data.quicklinks()
  }

  function show(section) {
    const shortcutPage = settings.parts.shortcutsScroll
    if (shortcutPage.moreMenu) shortcutPage.moreMenu.close()
    for (let index = 0; index < shortcutPage.desktopRepeater.count; index++) {
      const row = shortcutPage.desktopRepeater.itemAt(index)
      row.infoPopup.close()
      row.removing = false
      row.localError = ""
    }
    shortcutsDemo.cancelRecording()
    shortcutsDemo.active = null
    shortcutsDemo.queue = []
    shortcutsDemo.busyId = ""
    shortcutsDemo.conflict = null
    preparingShot = section === "shortcuts-preparing"
    galleryStage.deck.settingsOpen = true
    settings.agentChallenge = null
    galleryStage.deck.applyInterfaceFont(section === "font-shell" ? "shell" : "sans")
    const customization = ["display", "layout", "customization", "choices", "narrow", "font-shell"].indexOf(section) >= 0
    const page = section.indexOf("shortcuts-") === 0 ? "shortcuts" : customization ? "customization" : ["limits", "trust-duration", "quick-answers"].indexOf(section) >= 0 ? "ai"
      : ["ai", "editors", "filters", "shortcuts", "diagnostics"].indexOf(section) >= 0 ? section : "search"
    const queries = { display: "display size", layout: "layout", folders: "indexed folders", search: "ranking",
      choices: "closing reopening", limits: "limits", "trust-duration": "trust context", "font-shell": "interface font",
      quicklinks: "web searches", "quicklink-edit": "web searches" }
    showPage(page)
    searchControl.text = queries[section] || ""
    Qt.callLater(function() {
      settings.showPage(page)
      if (page === "ai") settings.part_aiHub.section = section === "quick-answers" ? "quick" : "assistant"
      if (section === "trust-duration") {
        settings.agentChallenge = { id: "gallery-trust", targetLevel: 6, requiresPhrase: true,
          requiresDuration: true, prompt: "Confirm unrestricted authority", warnings: [] }
        settings.agentDurationControl.currentIndex = 1
      }
      const shortcuts = settings.parts.shortcutsScroll
      if (section === "shortcuts-recording" || section === "shortcuts-preparing") shortcuts.desktopRepeater.itemAt(1).pill.startRecording()
      if (section === "shortcuts-conflict") shortcutsDemo.conflict = {
        operation: Protocol.Operations.ShortcutSet, shortcut: {id: "balance", chord: "Super+Q"}, description: "Omarchy menu" }
      if (section === "shortcuts-remove") shortcuts.desktopRepeater.itemAt(0).removing = true
      if (section === "shortcuts-error") shortcuts.desktopRepeater.itemAt(0).localError = "The shortcut could not be saved."
      if (section === "shortcuts-readonly") shortcuts.desktopRepeater.itemAt(3).infoPopup.open()
      if (section === "shortcuts-menu") shortcuts.moreMenu.open()
      if (section === "choices") settings.keepSearchControl.popup.open()
      if (section === "quicklink-edit") {
        const edit = settings.namedItem(settings.part_quicklinksCard, "quicklinkEdit-demo-docs")
        edit.clicked()
      } else if (section !== "choices" && section !== "shortcuts-recording" && section !== "shortcuts-preparing") {
        settings.searchControl.forceActiveFocus()
      }
    })
  }

  function namedItem(parent, name) {
    if (parent.objectName === name) return parent
    for (const child of parent.children) {
      const match = namedItem(child, name)
      if (match) return match
    }
    return null
  }

  // Fail capture if a card's task controls fall outside the rendered viewport.
  function verify(section) {
    let controls = [searchControl, closeControl]
    if (section === "display") controls.push(displaySizeControl)
    if (section === "layout") controls.push(layoutWidthControl, layoutHeightControl)
    if (section === "trust-duration") controls.push(agentDurationControl)
    if (section === "search") controls.push(namedItem(part_behaviorCard, "topMatchesToggle"))
    if (section === "folders") {
      if (part_indexRootsCard.renderedCount !== indexRoots.length) {
        return reject("The gallery must render every indexed folder")
      }
      let missing = false
      let disabled = false
      for (let index = 0; index < indexRoots.length; index++) {
        const root = indexRoots[index]
        const action = part_indexRootsCard.actionControlAt(index)
        if (!root.enabled && (root.issue || root.status !== "Disabled")) {
          return reject("Disabled gallery folders must have no warning")
        }
        if (root.source === "configuration" && root.issue === "Folder does not exist.") {
          missing = root.enabled && root.status === "Needs attention" && action.text === "Disable"
        }
        if (!root.enabled && action.text === "Enable") disabled = true
        controls.push(action)
      }
      if (!missing || !disabled) {
        return reject("The gallery must show an enabled missing folder with Disable and a disabled folder with Enable")
      }
      controls.push(part_indexRootsCard.pathControl)
    }
    if (section === "quicklinks") controls.push(namedItem(part_quicklinksCard, "quicklinkEdit-demo-docs"))
    if (section === "quicklink-edit") {
      controls.push(namedItem(part_quicklinksCard, "quicklinkTitle"), namedItem(part_quicklinksCard, "quicklinkSave"))
    }

    if (section === "choices") {
      const choice = keepSearchControl
      const popup = choice.popup
      const origin = choice.mapToItem(galleryStage.view.contentItem, popup.x, popup.y)
      if (!popup.visible || origin.x < 0 || origin.x + popup.width > galleryStage.view.width)
        return reject("The gallery choice popup must fit inside the window")
    }
    for (const control of controls) {
      if (!control || !control.visible || control.width <= 0 || control.height <= 0) {
        return reject("Missing gallery Settings control: " + section)
      }
      for (let parent = control.parent; parent; parent = parent.parent) {
        if (parent !== settings && !parent.clip) continue
        const point = control.mapToItem(parent, 0, 0)
        if (point.x < -1 || point.y < -1 || point.x + control.width > parent.width + 1
            || point.y + control.height > parent.height + 1) {
          return reject("Clipped gallery Settings control: " + section)
        }
      }
    }
    return true
  }

  function reject(message) {
    console.error(message)
    return false
  }
}
