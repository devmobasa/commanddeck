import "../.."
pragma ComponentBehavior: Bound
import QtQuick
import "../../Protocol.js" as Protocol
import "../../UiConstants.js" as Ui
import QtQuick.Controls
import QtQuick.Layouts
import "../DiagnosticsRows.js" as DiagnosticsRows

// What the daemon reports about itself, ready to paste into a bug report:
// every value has its own Copy button, and Copy debug info takes them all.
ScrollView {
  required property var host
  readonly property alias part_daemonDiagnosticsCard: daemonDiagnosticsCard
  readonly property alias part_copyReportButton: copyReport
  readonly property var rows: DiagnosticsRows.rows(diagnosticsScroll.host.runtimeStatus)
  readonly property bool shown: diagnosticsScroll.host.visible && diagnosticsScroll.host.currentPage === Ui.SettingsPage.Diagnostics
  property string copiedLabel: ""

  id: diagnosticsScroll
  clip: true
  contentWidth: availableWidth
  contentHeight: diagnosticsColumn.implicitHeight

  // The status is read fresh each time the page is shown.
  onShownChanged: if (diagnosticsScroll.shown) diagnosticsScroll.host.runtimeStatusRequested()

  function copy(label, value) {
    clipboardHelper.text = value
    clipboardHelper.selectAll()
    clipboardHelper.copy()
    clipboardHelper.text = ""
    diagnosticsScroll.copiedLabel = label
    copiedReset.restart()
  }

  TextEdit {
    id: clipboardHelper
    visible: false
    width: 1
    height: 1
  }

  Timer {
    id: copiedReset
    interval: 2000
    onTriggered: diagnosticsScroll.copiedLabel = ""
  }

  ColumnLayout {
    id: diagnosticsColumn
    width: diagnosticsScroll.availableWidth
    spacing: Math.round(22 * diagnosticsScroll.host.theme.scale)

    SettingsCard {
      id: daemonDiagnosticsCard
      theme: diagnosticsScroll.host.theme
      title: "Status and timings"
      description: "The daemon's version, index, and how recent searches performed. Durations only; no search text is kept."
      searchQuery: diagnosticsScroll.host.part_settingsSearch.text
      settingId: Protocol.SettingIds.Diagnostics

      Text {
        Layout.fillWidth: true
        visible: diagnosticsScroll.rows.length === 0
        text: "Waiting for the daemon…"
        color: diagnosticsScroll.host.theme.textMuted
        font.family: diagnosticsScroll.host.theme.fontFamily
        font.pixelSize: diagnosticsScroll.host.theme.fontBody
      }

      Repeater {
        id: diagnosticRows
        model: diagnosticsScroll.rows

        RowLayout {
          id: diagnosticRow
          required property var modelData
          objectName: "diagnosticRow"
          Layout.fillWidth: true
          spacing: Math.round(12 * diagnosticsScroll.host.theme.scale)
          Accessible.role: Accessible.ListItem
          Accessible.name: diagnosticRow.modelData.label + ": " + diagnosticRow.modelData.value

          Text {
            Layout.preferredWidth: Math.round(150 * diagnosticsScroll.host.theme.scale)
            text: diagnosticRow.modelData.label
            textFormat: Text.PlainText
            elide: Text.ElideRight
            color: diagnosticsScroll.host.theme.textMuted
            font.family: diagnosticsScroll.host.theme.fontFamily
            font.pixelSize: diagnosticsScroll.host.theme.fontBody
          }

          Text {
            Layout.fillWidth: true
            text: diagnosticRow.modelData.value
            textFormat: Text.PlainText
            wrapMode: Text.WrapAnywhere
            color: diagnosticsScroll.host.theme.text
            font.family: diagnosticsScroll.host.theme.monoFontFamily
            font.pixelSize: diagnosticsScroll.host.theme.fontBody
          }

          DeckButton {
            theme: diagnosticsScroll.host.theme
            compact: true
            text: diagnosticsScroll.copiedLabel === diagnosticRow.modelData.label ? "Copied" : "Copy"
            Accessible.name: "Copy " + diagnosticRow.modelData.label
            onClicked: diagnosticsScroll.copy(diagnosticRow.modelData.label, diagnosticRow.modelData.value)
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Math.round(8 * diagnosticsScroll.host.theme.scale)

        DeckButton {
          id: copyReport
          objectName: "copyDebugInfo"
          theme: diagnosticsScroll.host.theme
          text: diagnosticsScroll.copiedLabel === "report" ? "Copied" : "Copy debug info"
          enabled: diagnosticsScroll.rows.length > 0
          Accessible.name: "Copy debug info"
          onClicked: diagnosticsScroll.copy("report", DiagnosticsRows.report(diagnosticsScroll.rows))
        }

        DeckButton {
          theme: diagnosticsScroll.host.theme
          text: "Refresh"
          Accessible.name: "Refresh diagnostics"
          onClicked: diagnosticsScroll.host.runtimeStatusRequested()
        }
      }
    }
  }
}
