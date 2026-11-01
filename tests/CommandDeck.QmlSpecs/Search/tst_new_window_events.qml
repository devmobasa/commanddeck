import ".."
import QtQuick
import QtTest
import "../../../qml/common/Launcher/Actions/DeckInvocationActions.js" as Invocation

EventPathFixture {
  id: scene

  SignalSpy { id: newWindows; target: scene.part_controller; signalName: "newWindowRequested" }

  // The launcher state Shift+Enter reads, and the action it would run.
  QtObject {
    id: launcher
    property bool daemonAvailable: true
    property bool reconciliationPending: false
    property var selected: null
    property var invoked: null
    property var part_navigation: ({ selectedResult: () => launcher.selected })
    function invokeAction(result, action) { launcher.invoked = action }
  }

  EventPathTestCase {
    fixture: scene
    name: "CommandDeck_new_window"

    function test_shift_enter_asks_for_a_new_window() {
      fixture.part_searchField.inputControl.forceActiveFocus()
      newWindows.clear()
      const primaries = fixture.part_controller.primaryCalls
      keyClick(Qt.Key_Return, Qt.ShiftModifier)
      compare(newWindows.count, 1)
      compare(fixture.part_controller.primaryCalls, primaries, "Shift+Enter is not the primary action")
      keyClick(Qt.Key_Return)
      compare(fixture.part_controller.primaryCalls, primaries + 1)
      compare(newWindows.count, 1)
    }

    function test_new_window_runs_open_new_window_or_the_primary_action() {
      const launch = { id: "launch", title: "Launch", kind: "launch-desktop" }
      const fresh = { id: "launch-new", title: "Open New Window", kind: "launch-desktop", arguments: { newInstance: "true" } }

      launcher.selected = { kind: "application", actions: [launch, fresh] }
      Invocation.invokeSelectedNewWindow(launcher)
      compare(launcher.invoked, fresh)

      // A row without Open New Window, such as a file, runs its primary action.
      launcher.selected = { kind: "custom-command", actions: [launch] }
      Invocation.invokeSelectedNewWindow(launcher)
      compare(launcher.invoked, launch)
    }
  }
}
