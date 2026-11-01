pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "./DemoData.js" as Data
import "./HerdrRows.js" as Herdr
import "./HerdrJumpData.js" as Jump

// A captioned jump across Hyprland workspaces: from an editor on workspace 1,
// `herdr: auth` finds the tab and Enter lands on workspace 3, where Herdr now
// shows taskboard › auth flow. The windows are text captures of a throwaway
// Herdr server, nvim, and lazygit with fictional projects; the workspace
// switch is drawn as Hyprland's horizontal slide. Typed queries filter the
// Herdr rows by label; the daemon does not rank them.
ShellRoot {
  id: root
  property bool launcherOpen: false
  property int workspace: 1
  // 0 shows workspace 1, 1 shows workspace 3; frames between draw the slide.
  property real slide: 0
  readonly property string terminalIcon: stage.icon("utilities-terminal")
  readonly property int gap: 10
  readonly property int barHeight: 26
  readonly property var occupied: [1, 3]

  DemoStage {
    id: stage
    filters: Herdr.filters(Data.filters)
    captionSize: 18
    shots: root.storyboard()
    onShotSaved: {
      const shot = stage.shots[stage.shotIndex]
      if (shot.expect) {
        const selected = stage.deck.part_navigation.selectedResult()
        if (!selected || selected.title !== shot.expect) root.fail(shot.name + " must select " + shot.expect)
      }
      if (shot.results !== undefined && root.resultCount() !== shot.results) {
        root.fail(shot.name + " must list " + shot.results + " results")
      }
    }
    underlays: [
      Rectangle {
        id: monitor
        x: Math.round((stage.view.width - width) / 2)
        y: 18
        width: 1232
        height: root.barHeight + root.gap * 2 + herdrScreen.height + 4
        clip: true
        gradient: Gradient {
          GradientStop { position: 0; color: "#1f2335" }
          GradientStop { position: 1; color: "#16161e" }
        }

        Item {
          id: workspaces
          x: -Math.round(root.slide * monitor.width)
          y: root.barHeight
          width: monitor.width * 2
          height: monitor.height - root.barHeight

          // Workspace 1: the editor and lazygit, tiled side by side.
          Rectangle {
            id: editorWindow
            x: root.gap
            y: root.gap
            width: (monitor.width - root.gap * 3) / 2
            height: herdrScreen.height + 4
            color: "#14161b"
            border.width: 2
            border.color: "#7aa2f7"

            TerminalScreen {
              x: 2
              y: 2
              width: implicitWidth
              height: implicitHeight
              color: parent.color
              lineHeight: 1.25
              screen: Jump.editor
            }
          }

          Rectangle {
            x: editorWindow.x + editorWindow.width + root.gap
            y: root.gap
            width: editorWindow.width
            height: editorWindow.height
            color: Jump.background
            border.width: 2
            border.color: "#414868"

            TerminalScreen {
              x: 2
              y: 2
              width: implicitWidth
              height: implicitHeight
              color: parent.color
              lineHeight: 1.25
              screen: Jump.git
            }
          }

          // Workspace 3: Herdr, after the focus action switched its tab.
          Rectangle {
            x: monitor.width + root.gap
            y: root.gap
            width: monitor.width - root.gap * 2
            height: herdrScreen.height + 4
            color: Jump.background
            border.width: 2
            border.color: "#7aa2f7"

            TerminalScreen {
              id: herdrScreen
              x: 2
              y: 2
              width: implicitWidth
              height: implicitHeight
              color: parent.color
              lineHeight: 1.25
              screen: Jump.herdr
            }
          }
        }

        // A Waybar-style strip: workspace numbers and a clock.
        Rectangle {
          width: monitor.width
          height: root.barHeight
          color: "#16161e"

          Row {
            x: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14

            Repeater {
              model: 5

              Text {
                required property int index
                readonly property int number: index + 1
                text: String(number)
                font.family: "monospace"
                font.pixelSize: 12
                font.bold: number === root.workspace
                color: number === root.workspace ? "#7aa2f7"
                  : root.occupied.indexOf(number) >= 0 ? "#a9b1d6" : "#565f89"
              }
            }
          }

          Text {
            anchors.centerIn: parent
            text: "10:42"
            font.family: "monospace"
            font.pixelSize: 12
            color: "#a9b1d6"
          }
        }

        Rectangle {
          anchors.fill: parent
          color: stage.view.color
          opacity: root.launcherOpen ? 0.72 : 0
        }
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

  function resultCount() {
    const navigation = stage.deck.part_navigation
    let count = 0
    for (let index = 0; index < navigation.rowCount(); index++) {
      if (navigation.resultAt(index)) count++
    }
    return count
  }

  function storyboard() {
    const steps = []
    const add = function(hold, caption, show, check) {
      steps.push({ hold: hold, caption: caption, show: show, check: check || {} })
    }
    const type = function(text, hold, last, caption, show, check) {
      for (let length = 1; length <= text.length; length++) {
        const typed = text.slice(0, length)
        const done = length === text.length
        add(done ? last : hold, caption, function() { show(typed) }, done ? check : null)
      }
    }

    add(2400, "Hyprland workspace 1 · Herdr is on workspace 3", root.showDesktop)
    add(900, "Ctrl+Space", root.showHome)
    type("herdr:", 100, 900, "Type herdr: and part of a tab name", root.typePrefix, { results: 29 })
    type("auth", 130, 1600, "herdr: auth · the auth flow tab in taskboard", root.typeQuery,
      { expect: "auth flow", results: 1 })
    for (const progress of [0.16, 0.45, 0.72, 0.9, 0.97]) {
      add(45, "Enter", function() { root.showSlide(progress) })
    }
    add(4000, "Hyprland workspace 3 · Herdr on taskboard › auth flow", function() { root.showSlide(1) })

    return steps.map(function(step, index) {
      return {
        name: "frame-" + String(index + 1).padStart(4, "0") + "-" + String(step.hold).padStart(5, "0") + ".png",
        frame: { width: 1280, height: 900 },
        caption: step.caption,
        settle: 400,
        show: step.show,
        expect: step.check.expect,
        results: step.check.results
      }
    })
  }

  function showDesktop() {
    root.launcherOpen = false
    root.workspace = 1
    root.slide = 0
  }

  function showHome() {
    root.launcherOpen = true
    stage.setResults("", Data.home(stage.icon), "Home")
    stage.content.part_searchBar.inputControl.forceActiveFocus()
  }

  function setInput(text) {
    stage.deck.queryText = text
    stage.content.part_searchBar.setInputText(text)
    stage.content.part_searchBar.inputControl.cursorPosition = text.length
  }

  // Home stays listed while the prefix is typed; the token becomes a filter.
  function typePrefix(text) {
    if (text !== "herdr:") {
      root.setInput(text)
      return
    }
    const rows = Herdr.browse(Jump.spaces, Jump.tabs, root.terminalIcon, true, true)
    stage.setResults(text, rows, rows.length + " results")
  }

  // After the filter chip, the text matches labels: a tab by its own label or
  // its space's, a space by its label. Label starts rank first.
  function typeQuery(text) {
    const needle = text.toLowerCase()
    const rank = function(label) {
      const value = label.toLowerCase()
      return value.startsWith(needle) ? 3 : value.split(/[\s-]/).some(function(word) { return word.startsWith(needle) }) ? 2
        : value.indexOf(needle) >= 0 ? 1 : 0
    }
    const rows = Herdr.browse(Jump.spaces, Jump.tabs, root.terminalIcon, true, true)
      .map(function(row, order) {
        const own = rank(row.title)
        const parent = row.kind === "tab" ? rank(row.metadata.herdrWorkspaceLabel) / 2 : 0
        return { row: row, order: order, score: Math.max(own, parent) }
      })
      .filter(function(entry) { return entry.score > 0 })
      .sort(function(left, right) { return (right.score - left.score) || (left.order - right.order) })
      .map(function(entry) { return entry.row })
    root.setInput(text)
    stage.deck.part_navigation.replaceResults(rows, true)
    stage.deck.previewLoading = false
    stage.deck.activePreviewRequestId = 0
    stage.deck.statusText = rows.length + (rows.length === 1 ? " result" : " results")
  }

  // Enter runs Switch Herdr Tab: Herdr switches, then CommandDeck focuses its
  // window and Hyprland slides to the workspace that holds it.
  function showSlide(progress) {
    root.launcherOpen = false
    root.workspace = 3
    root.slide = progress
  }
}
