import ".."
import QtQuick
import QtTest
import "../../../qml/common" as CommandDeck

// Modal surfaces keep Tab and Shift+Tab on their own usable controls: focus
// wraps at the ends, skips hidden and disabled controls, and never rests on
// the surface itself. Real keys from the surface's focused control.
Item {
  id: scene
  width: 900
  height: 700

  CommandDeck.Theme { id: appTheme; loadShellTokens: false }
  LiteralTextProbe { id: literal }

  function workItems(count) {
    const values = []
    for (let index = 0; index < count; index++) {
      values.push({ path: "/tmp/item-" + index, state: "failed", reason: "unreadable" })
    }
    return values
  }

  function inspection(count) {
    return { workItems: scene.workItems(count), failedItemCount: count, staleItemCount: 0,
      pendingItemCount: 0, totalExclusionDiagnosticCount: 0, stats: { itemCount: 10 } }
  }

  CommandDeck.IndexInspector {
    id: inspector
    anchors.fill: parent
    theme: appTheme
    onDismissed: opened = false
  }

  SignalSpy { id: stopIndexing; target: inspector; signalName: "stopIndexingRequested" }

  CommandDeck.RuntimeStatusSurface {
    id: statusSurface
    visible: false
    theme: appTheme
  }

  DeadlineTestCase {
    name: "FocusTrap"
    when: windowShown

    function focused() { return inspector.Window.window.activeFocusItem }

    function cleanup() {
      inspector.opened = false
      inspector.healthDetails = ""
      inspector.missingRoots = []
      inspector.foldersRelevant = true
      statusSurface.status = null
      stopIndexing.clear()
    }

    // Named to run before the Tab tests below: a missing indexed folder gets a
    // Stop indexing button in the Tab cycle, and the status text drops the
    // watch-limit advice for it.
    function test_inspector_offers_stop_indexing_for_a_missing_folder() {
      statusSurface.status = { indexing: { roots: [
        { id: "missing-root", path: "/home/demo/Projects", watched: false, paused: false, missing: true,
          lastError: "Folder does not exist.", remediation: "Stop indexing this folder, or create it." },
        { id: "broken-root", path: "/home/demo/Notes", watched: false, paused: false,
          lastError: "Watch failed.", remediation: "Check the root path and inotify limits." }] } }
      compare(statusSurface.missingRoots.length, 1, "only the missing folder offers Stop indexing")
      compare(statusSurface.missingRoots[0].id, "missing-root")
      verify(statusSurface.details.indexOf("Indexed folder missing: /home/demo/Projects does not exist. "
        + "Stop indexing this folder, or create it.") >= 0)
      verify(statusSurface.details.indexOf("inotify") > statusSurface.details.indexOf("/home/demo/Notes"),
        "the watch-limit advice stays on the other folder")

      inspector.healthDetails = statusSurface.details
      inspector.missingRoots = statusSurface.missingRoots
      inspector.inspection = scene.inspection(2)
      inspector.opened = true
      waitForValue(inspector.closeControl, "activeFocus", true)
      const stop = inspector.stopIndexingControl
      verify(stop.visible)
      compare(stop.text, "Stop indexing ~/Projects")

      keyClick(Qt.Key_Tab)
      compare(focused(), inspector.healthControl)
      keyClick(Qt.Key_Tab)
      compare(focused(), stop, "Tab reaches Stop indexing before folder management")
      keyClick(Qt.Key_Tab)
      compare(focused(), inspector.foldersControl)

      keyClick(Qt.Key_Tab, Qt.ShiftModifier)
      compare(focused(), stop)
      keyClick(Qt.Key_Space)
      compare(stopIndexing.count, 1)
      compare(stopIndexing.signalArguments[0][0], "missing-root")
      keyClick(Qt.Key_Escape)
      verify(!inspector.opened)
    }

    function test_inspector_tab_stays_on_close_when_it_is_the_only_control() {
      inspector.inspection = scene.inspection(2)
      inspector.opened = true
      waitForValue(inspector.closeControl, "activeFocus", true)
      verify(!inspector.previousControl.enabled && !inspector.nextControl.enabled)

      keyClick(Qt.Key_Tab)
      compare(focused(), inspector.closeControl, "Tab keeps focus on Close")
      keyClick(Qt.Key_Tab, Qt.ShiftModifier)
      compare(focused(), inspector.closeControl, "Shift+Tab keeps focus on Close")
      verify(literal.labelShowing(inspector,
        "Files: Indexed 10 · Excluded about 0 · Failed 2 · Stale 0 · Pending 0") !== null)
      keyClick(Qt.Key_Escape)
      verify(!inspector.opened)
    }

    function test_inspector_tab_skips_the_disabled_page_button_and_wraps() {
      inspector.healthDetails = "The clipboard service is not running."
      inspector.inspection = scene.inspection(6)
      inspector.opened = true
      waitForValue(inspector.closeControl, "activeFocus", true)
      verify(!inspector.previousControl.enabled && inspector.nextControl.enabled)

      keyClick(Qt.Key_Tab)
      compare(focused(), inspector.healthControl)
      keyClick(Qt.Key_Tab)
      compare(focused(), inspector.foldersControl, "Tab reaches indexed folder management")
      keyClick(Qt.Key_Tab)
      compare(focused(), inspector.nextControl, "Tab skips the disabled Previous button")
      keyClick(Qt.Key_Tab)
      compare(focused(), inspector.closeControl, "Tab wraps to Close")
      keyClick(Qt.Key_Tab, Qt.ShiftModifier)
      compare(focused(), inspector.nextControl, "Shift+Tab wraps to the last control")

      keyClick(Qt.Key_PageDown)
      compare(inspector.page, 1)
      verify(inspector.previousControl.enabled && !inspector.nextControl.enabled)
      inspector.closeControl.forceActiveFocus()
      keyClick(Qt.Key_Tab, Qt.ShiftModifier)
      compare(focused(), inspector.previousControl, "Shift+Tab skips the disabled Next button")

      keyClick(Qt.Key_Escape)
      verify(!inspector.opened, "Escape dismisses the inspector")
    }

    // Folders cannot help a service issue, so its inspector leaves out Manage
    // indexed folders; an index issue beside it brings the button back.
    function test_service_issue_hides_folder_management() {
      statusSurface.status = { providers: [{ id: "herdr", label: "Herdr", state: "degraded",
        detail: "Herdr status exited with code 139." }] }
      verify(!statusSurface.hasIndexIssue)
      inspector.foldersRelevant = statusSurface.hasIndexIssue
      inspector.healthDetails = statusSurface.details
      inspector.inspection = scene.inspection(2)
      inspector.opened = true
      waitForValue(inspector.closeControl, "activeFocus", true)
      verify(inspector.healthControl.visible)
      verify(!inspector.foldersControl.visible)

      statusSurface.status = { providers: statusSurface.status.providers, indexing: { roots: [
        { id: "missing-root", path: "/home/demo/Projects", watched: false, paused: false, missing: true,
          lastError: "Folder does not exist." }] } }
      verify(statusSurface.hasIndexIssue)
      inspector.foldersRelevant = statusSurface.hasIndexIssue
      verify(inspector.foldersControl.visible)
    }
  }
}
