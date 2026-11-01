import "../.."
import QtQuick
import QtQuick.Layouts

// Label and help on the left, the control on the right. The group owns dividers.
// The label column never collapses, so long control text cannot push the
// caption out of view the way the old free-form rows did.
//
// The row is responsive: when the width cannot hold the label column (at its
// minimum) and the control column (at its implicit/minimum width) side by
// side, the control drops beneath the label and takes the full row width. This
// keeps wide controls and their buttons from clipping at high display scale.
Item {
  id: root

  required property var theme
  property string label: ""
  property string help: ""
  property string tag: ""
  readonly property bool settingsRow: true
  property bool divider: false
  property int controlMinimumWidth: Math.round(90 * root.theme.scale)
  default property alias control: slot.data

  readonly property int rowSpacing: Math.round(16 * root.theme.scale)
  readonly property int stackSpacing: Math.round(6 * root.theme.scale)
  readonly property int labelMinimum: Math.round(160 * root.theme.scale)
  // The control column's natural width: its own content, but never below the
  // caller's floor.
  readonly property int controlMinimum: Math.max(root.controlMinimumWidth, Math.round(slot.implicitWidth))
  // Stack when the label column and the control column cannot fit beside each
  // other in the available width. `stacked` drives both the arrangement and the
  // height, so a spec can read it to confirm the reflow.
  readonly property bool stacked: root.width > 0
    && root.width < root.labelMinimum + root.controlMinimum + root.rowSpacing

  Layout.fillWidth: true
  implicitHeight: (root.stacked
    ? labels.implicitHeight + root.stackSpacing + slot.implicitHeight
    : Math.max(labels.implicitHeight, slot.implicitHeight))
    + Math.round(16 * root.theme.scale)
  Layout.minimumHeight: Math.round(root.theme.fontBody * 2.75)
  Accessible.role: Accessible.Grouping
  Accessible.name: root.label

  GridLayout {
    anchors.fill: parent
    anchors.topMargin: Math.round(8 * root.theme.scale)
    anchors.bottomMargin: Math.round(8 * root.theme.scale)
    // Two columns side by side, one column stacked.
    columns: root.stacked ? 1 : 2
    columnSpacing: root.rowSpacing
    rowSpacing: root.stackSpacing

    ColumnLayout {
      id: labels
      Layout.fillWidth: true
      Layout.minimumWidth: root.labelMinimum
      Layout.preferredWidth: root.stacked ? -1 : Math.round(root.width * 0.46)
      Layout.alignment: Qt.AlignVCenter
      spacing: Math.round(2 * root.theme.scale)

      RowLayout {
        Layout.fillWidth: true
        Text {
        Layout.fillWidth: root.tag.length === 0
        Layout.maximumWidth: Math.max(0, labels.width - (tagText.visible ? tagText.implicitWidth + root.rowSpacing : 0))
        textFormat: Text.PlainText
        text: root.label
        color: root.theme.text
        wrapMode: Text.Wrap
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.fontBody
        font.weight: Font.Normal
        }
        Text {
          id: tagText
          visible: root.tag.length > 0
          text: root.tag
          color: root.theme.textMuted
          font.family: root.theme.fontFamily
          font.pixelSize: root.theme.fontSmall
        }
        Item { Layout.fillWidth: true; visible: root.tag.length > 0 }
      }

      Text {
        Layout.fillWidth: true
        visible: text.length > 0
        textFormat: Text.PlainText
        text: {
          const descriptions = []
          for (const child of slot.children) {
            if (child.showCurrentDescription && child.currentDescription)
              descriptions.push(child.currentDescription)
          }
          return [root.help].concat(descriptions).filter(value => value.length > 0).join("\n")
        }
        color: root.theme.textMuted
        wrapMode: Text.Wrap
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.fontSmall
      }

      Text {
        Layout.fillWidth: true
        objectName: "settingsChoiceWarning"
        text: slot.children.filter(child => child.currentWarning).map(child => child.currentWarning).join("\n")
        visible: text.length > 0
        color: root.theme.urgent
        wrapMode: Text.Wrap
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.fontSmall
        Accessible.role: Accessible.StaticText
        Accessible.name: text
      }
    }

    RowLayout {
      id: slot
      // Keep controls at their natural width against the right inset. On a
      // narrow row they take the full line below the label.
      Layout.fillWidth: root.stacked
      Layout.minimumWidth: root.controlMinimum
      Layout.preferredWidth: root.stacked ? -1 : Math.max(root.controlMinimum, slot.implicitWidth)
      Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
      spacing: Math.round(8 * root.theme.scale)
    }
  }

  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 1
    visible: root.divider && root.parent.objectName !== "settingsGroupBody"
    color: root.theme.separator
  }
}
