pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "./DemoData.js" as Data
import "./HerdrRows.js" as Herdr
import "./HerdrTourData.js" as Tour

// A captioned tour over a captured Herdr session: CommandDeck opens over
// Herdr, lists its ten spaces, browses the third space's six tabs, and jumps
// to the fourth. The Herdr screens are text captures of a throwaway Herdr
// server with fictional projects; the rows follow HerdrProvider's shapes.
ShellRoot {
  id: root
  property bool launcherOpen: false
  property bool switched: false
  readonly property string terminalIcon: stage.icon("utilities-terminal")
  readonly property var filters: Herdr.filters(Data.filters)

  DemoStage {
    id: stage
    filters: root.filters
    captionSize: 18
    shots: root.storyboard()
    onShotSaved: {
      const shot = stage.shots[stage.shotIndex]
      if (shot.expect) {
        const selected = stage.deck.part_navigation.selectedResult()
        if (!selected || selected.title !== shot.expect) root.fail(shot.name + " must select " + shot.expect)
      }
      const browsing = stage.deck.part_navigation.herdrWorkspaceId.length > 0
      if (shot.browsing !== undefined && browsing !== shot.browsing) {
        root.fail(shot.name + (shot.browsing ? " must browse a Herdr space" : " must not browse a Herdr space"))
      }
    }
    underlays: [
      Rectangle {
        id: herdrWindow
        x: Math.round((stage.view.width - width) / 2)
        y: 24
        width: terminal.width + 4
        height: terminal.height + 4
        color: Tour.background
        border.width: 2
        border.color: root.launcherOpen ? "#2f3549" : "#7aa2f7"

        TerminalScreen {
          id: terminal
          x: 2
          y: 2
          width: implicitWidth
          height: implicitHeight
          color: Tour.background
          screen: root.switched ? Tour.after : Tour.before
        }
      },
      Rectangle {
        anchors.fill: parent
        color: stage.view.color
        opacity: root.launcherOpen ? 0.72 : 0
      }
    ]
  }

  Binding {
    target: stage.panel
    property: "visible"
    value: root.launcherOpen
  }

  function fail(message) {
    console.error(message)
    Qt.exit(1)
  }

  function storyboard() {
    const steps = []
    const add = function(hold, caption, show, check) {
      steps.push({ hold: hold, caption: caption, show: show, check: check || {} })
    }
    const type = function(text, hold, caption, show) {
      for (let length = 1; length <= text.length; length++) {
        const typed = text.slice(0, length)
        add(length === text.length ? 1500 : hold, caption, function() { show(typed) })
      }
    }

    add(2400, "A busy Herdr session · 10 spaces, 19 tabs, agents at work", root.showHerdr)
    add(1000, "Ctrl+Space · CommandDeck opens over Herdr", root.showHome)
    type("hspace:", 110, "Type hspace: to list every Herdr space", root.typeSpaces)
    add(450, "↓↓ to the third space", function() { stage.move(1) })
    add(1800, "taskboard · the preview lists its six tabs", function() { stage.move(1) },
      { expect: "taskboard", browsing: false })
    add(1700, "Ctrl+Enter · browse taskboard's tabs", root.browseSpace, { expect: "dev server", browsing: true })
    add(350, "↓↓↓ to the fourth tab", function() { stage.move(1) })
    add(350, "↓↓↓ to the fourth tab", function() { stage.move(1) })
    add(1500, "auth flow · Tab 4 · 2 panes", function() { stage.move(1) }, { expect: "auth flow", browsing: true })
    add(3600, "Enter · Herdr jumps straight to taskboard › auth flow", root.switchTab)

    return steps.map(function(step, index) {
      return {
        name: "frame-" + String(index + 1).padStart(4, "0") + "-" + String(step.hold).padStart(5, "0") + ".png",
        frame: { width: 1280, height: 900 },
        caption: step.caption,
        settle: 400,
        show: step.show,
        expect: step.check.expect,
        browsing: step.check.browsing
      }
    })
  }

  function showHerdr() {
    root.launcherOpen = false
    root.switched = false
  }

  function showHome() {
    root.launcherOpen = true
    stage.setResults("", Data.home(stage.icon), "Home")
    stage.content.part_searchBar.inputControl.forceActiveFocus()
  }

  // Home stays listed while the prefix is typed; the token becomes a filter.
  function typeSpaces(text) {
    if (text !== "hspace:") {
      stage.deck.queryText = text
      stage.content.part_searchBar.setInputText(text)
      stage.content.part_searchBar.inputControl.cursorPosition = text.length
      return
    }
    const rows = Herdr.browse(Tour.spaces, Tour.tabs, root.terminalIcon, true, false)
    stage.setResults(text, rows, rows.length + " results")
  }

  // Ctrl+Enter runs Browse tabs, the space row's second action.
  function browseSpace() {
    const navigation = stage.deck.part_navigation
    const space = navigation.selectedResult()
    navigation.browseHerdrSpace(space)
    const owner = Tour.spaces.find(function(value) { return value.id === space.metadata.herdrWorkspaceId })
    const rows = Herdr.spaceTabs(Tour.tabs, owner.id).map(function(tab) { return Herdr.tabRow(tab, owner, root.terminalIcon) })
    navigation.replaceResults(rows, true)
    stage.deck.previewLoading = false
    stage.deck.activePreviewRequestId = 0
    stage.deck.statusText = rows.length + " results"
  }

  function switchTab() {
    root.launcherOpen = false
    root.switched = true
  }
}
