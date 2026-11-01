import "../.."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../Protocol.js" as Protocol

Item {
  id: root
  required property var theme
  required property var binding
  property var controller: null
  property string operation: Protocol.Operations.ShortcutSet
  property bool globalShortcut: true
  property bool moduleInstalled: true
  property string localError: ""
  property string warning: ""
  property bool busy: false
  property bool pendingAddition: false
  property bool removing: false
  property var editValues: ({})
  readonly property bool settingsRow: true
  readonly property alias pill: shortcutPill
  readonly property alias infoPopup: info
  readonly property alias restoreControl: restoreButton
  readonly property alias removeControl: removeButton
  readonly property bool hasConflict: !!controller && !!controller.conflict && controller.conflict.shortcut.id === binding.id
  Accessible.role: Accessible.ListItem
  Accessible.name: (binding.chord || "Not set") + ": " + (binding.description || "No description")
  readonly property string inlineError: root.localError || (root.controller && root.controller.errorId === root.binding.id ? root.controller.error : "") || root.warning
  readonly property bool stacked: width > 0 && width < Math.round(176 * theme.scale) + controls.implicitWidth
  readonly property string infoSentence: {
    if (binding.sourceFile && (!binding.reason || binding.reason.indexOf("This binding is built") === 0))
      return "This binding is built by your Hyprland configuration, for example in a loop. Change it in:"
    const reason = binding.reason || "Change this shortcut in your Hyprland configuration."
    return binding.sourceFile ? reason.replace(binding.sourceFile, "").replace(/[ .:]+$/, "") + ":" : reason
  }
  Layout.fillWidth: true
  Layout.minimumHeight: Math.round(theme.fontBody * 2.75)
  implicitHeight: rowLayout.implicitHeight + Math.round(16 * theme.scale)

  function edit(chord, confirmed) {
    removing = false
    const values = Object.assign({}, editValues, { id: binding.id || "", chord: chord })
    if (controller) controller.change(operation, values, confirmed)
  }
  signal recorded(string chord)
  signal removeConfirmed()
  signal recordingStarted(var pill)
  signal recordingStopped()
  signal restoreRequested()
  signal copyRequested(string text)

  GridLayout {
    id: rowLayout
    anchors.fill: parent
    anchors.topMargin: Math.round(8 * root.theme.scale)
    anchors.bottomMargin: Math.round(8 * root.theme.scale)
    columns: root.stacked ? 1 : 2
    columnSpacing: Math.round(16 * root.theme.scale)
    rowSpacing: Math.round(6 * root.theme.scale)
    ColumnLayout {
      id: labels
      Layout.fillWidth: true
      Layout.minimumWidth: Math.min(root.width, Math.round(160 * root.theme.scale))
      Layout.alignment: Qt.AlignTop
      Layout.topMargin: root.stacked ? 0 : Math.max(0, (shortcutPill.implicitHeight - labelText.implicitHeight) / 2)
      spacing: Math.round(4 * root.theme.scale)
      RowLayout {
        id: labelLine
        Layout.fillWidth: true
        Text {
          id: labelText
          objectName: "shortcutRowLabel"
          Layout.fillWidth: !changedTag.visible
          Layout.maximumWidth: Math.max(0, root.width - (root.stacked ? 0 : controls.implicitWidth + rowLayout.columnSpacing)
            - (changedTag.visible ? changedTag.implicitWidth + labelLine.spacing : 0))
          text: (root.binding.description || "No description") + (root.binding.submap ? " · " + root.binding.submap + " submap" : "")
          textFormat: Text.PlainText
          wrapMode: Text.Wrap
          color: root.theme.text
          font.family: root.theme.fontFamily
          font.pixelSize: root.theme.fontBody
        }
        Text {
          id: changedTag
          visible: root.binding.changed === true
          text: "Changed"
          color: root.theme.textMuted
          font.family: root.theme.fontFamily
          font.pixelSize: root.theme.fontSmall
        }
        Item { Layout.fillWidth: true; visible: changedTag.visible }
      }
      Text {
        objectName: "shortcutRowMessage"
        visible: root.removing || root.hasConflict
        Layout.fillWidth: true
        text: root.hasConflict ? root.controller.conflict.shortcut.chord + " is used by " + root.controller.conflict.description + "."
          : "Remove " + shortcutPill.chord + " from " + root.binding.description + "?"
        wrapMode: Text.Wrap
        color: root.theme.textMuted
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.fontSmall
      }
      Text {
        Layout.fillWidth: true
        visible: shortcutPill.recording && root.globalShortcut && !root.moduleInstalled
        text: "Some keys are taken by Hyprland while you record. Install the CommandDeck hotkey module to record any key."
        wrapMode: Text.Wrap
        color: root.theme.textMuted
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.fontSmall
      }
      Text {
        objectName: "shortcutRowError"
        Layout.fillWidth: true
        visible: text.length > 0
        text: root.inlineError
        wrapMode: Text.Wrap
        color: root.theme.urgent
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.fontSmall
      }
    }
    ColumnLayout {
      id: controls
      Layout.alignment: Qt.AlignRight | Qt.AlignTop
      spacing: Math.round(4 * root.theme.scale)
      RowLayout {
        Layout.alignment: Qt.AlignRight
        spacing: Math.round(8 * root.theme.scale)
        DeckButton {
          id: infoButton
          theme: root.theme
          visible: root.binding.changeable !== true
          text: "ⓘ"
          compact: true
          Accessible.name: "Why this shortcut is read-only"
          onClicked: info.open()
          Popup {
            id: info
            y: infoButton.height + 4
            x: Math.min(0, infoButton.width - width)
            width: Math.round(root.theme.fontBody * 29)
            padding: Math.round(12 * root.theme.scale)
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
            background: Rectangle { color: root.theme.popupBackground; radius: 10; border.color: root.theme.separator }
            contentItem: ColumnLayout {
              Text {
                Layout.fillWidth: true
                text: root.infoSentence
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                color: root.theme.text
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.fontBody
              }
              Text {
                objectName: "shortcutSourcePath"
                Layout.fillWidth: true
                visible: !!root.binding.sourceFile
                text: root.binding.sourceFile || ""
                textFormat: Text.PlainText
                elide: Text.ElideMiddle
                color: root.theme.textMuted
                font.family: root.theme.monoFontFamily
                font.pixelSize: root.theme.fontBody
              }
              DeckButton {
                theme: root.theme
                visible: !!root.binding.sourceFile
                objectName: "copyShortcutSource"
                text: "Copy file path"
                compact: true
                onClicked: root.copyRequested(root.binding.sourceFile)
              }
            }
          }
        }
        DeckButton {
          id: restoreButton
          theme: root.theme
          visible: root.binding.changed === true || root.binding.added === true
          text: "↺"
          compact: true
          Accessible.name: "Restore original shortcut"
          ToolTip.visible: hovered
          ToolTip.text: "Restore original shortcut"
          onClicked: {
            root.removing = false
            root.restoreRequested()
            if (root.controller && !root.pendingAddition) root.controller.change(Protocol.Operations.ShortcutRestore, {id: root.binding.id}, true)
          }
        }
        SettingsShortcutPill {
          id: shortcutPill
          theme: root.theme
          actionName: root.binding.description || "No description"
          chord: root.binding.chord || ""
          pending: root.hasConflict
          proposedChord: root.hasConflict ? root.controller.conflict.shortcut.chord : ""
          captureRequired: root.globalShortcut && root.moduleInstalled && !!root.controller
          recordable: root.binding.changeable === true
          saving: root.busy || (!!root.controller && root.controller.isSaving(root.binding.id))
          onRecordingStarted: {
            root.removing = false
            root.localError = ""
            if (shortcutPill.captureRequired) root.controller.start(shortcutPill, root.binding.id)
            root.recordingStarted(shortcutPill)
          }
          onRecordingStopped: {
            if (root.controller && root.controller.recordingPill === shortcutPill) root.controller.stop()
            root.recordingStopped()
          }
          onRecorded: value => { root.recorded(value); if (root.globalShortcut) root.edit(value, false) }
          onRemovalRequested: root.removing = true
          onPreparationTimedOut: root.localError = "Shortcut recording could not start. Try again."
        }
      }
      RowLayout {
        Layout.alignment: Qt.AlignRight
        visible: root.removing || root.hasConflict
        DeckButton {
          id: removeButton
          kind: root.hasConflict ? "primary" : "secondary"
          theme: root.theme
          text: root.hasConflict ? "Replace" : "Remove"
          compact: true
          onClicked: {
            if (root.hasConflict) root.controller.replaceConflict()
            else {
              root.removeConfirmed()
              if (root.globalShortcut) root.edit("", true)
              root.removing = false
            }
          }
        }
        DeckButton {
          theme: root.theme
          objectName: "shortcutConfirmationCancel"
          text: "Cancel"
          compact: true
          onClicked: { root.removing = false; if (root.controller) root.controller.conflict = null }
        }
      }
    }
  }
}
