pragma ComponentBehavior: Bound
import QtQuick

// One captured terminal screen from a Herdr*Data.js file, drawn as text on a
// cell grid: fills, box-drawing strokes, then text runs at their columns.
Rectangle {
  id: terminal

  required property var screen
  property string fontFamily: "monospace"
  property int fontPixelSize: 13
  property real lineHeight: 1.3
  readonly property real cellWidth: metrics.advanceWidth("M")
  readonly property int cellHeight: Math.round(terminal.fontPixelSize * terminal.lineHeight)

  implicitWidth: Math.ceil(terminal.screen.cols * terminal.cellWidth)
  implicitHeight: terminal.screen.rows * terminal.cellHeight
  clip: true

  FontMetrics {
    id: metrics
    font.family: terminal.fontFamily
    font.pixelSize: terminal.fontPixelSize
  }

  Repeater {
    model: terminal.screen.fills

    Rectangle {
      required property var modelData
      x: modelData[1] * terminal.cellWidth
      y: modelData[0] * terminal.cellHeight
      width: modelData[2] * terminal.cellWidth
      height: terminal.cellHeight
      color: modelData[3]
    }
  }

  Repeater {
    model: terminal.screen.across

    Rectangle {
      required property var modelData
      x: modelData[1] * terminal.cellWidth
      y: Math.floor((modelData[0] + 0.5) * terminal.cellHeight)
      width: (modelData[2] - modelData[1]) * terminal.cellWidth
      height: 1
      color: modelData[3]
    }
  }

  Repeater {
    model: terminal.screen.down

    Rectangle {
      required property var modelData
      x: Math.floor((modelData[0] + 0.5) * terminal.cellWidth)
      y: modelData[1] * terminal.cellHeight
      width: 1
      height: (modelData[2] - modelData[1]) * terminal.cellHeight
      color: modelData[3]
    }
  }

  Repeater {
    model: terminal.screen.text

    Text {
      required property var modelData
      x: modelData[1] * terminal.cellWidth
      y: modelData[0] * terminal.cellHeight
      height: terminal.cellHeight
      verticalAlignment: Text.AlignVCenter
      textFormat: Text.PlainText
      text: modelData[2]
      color: modelData[3]
      opacity: modelData[4] & 2 ? 0.6 : 1
      font.family: terminal.fontFamily
      font.pixelSize: terminal.fontPixelSize
      font.bold: (modelData[4] & 1) !== 0
      font.italic: (modelData[4] & 4) !== 0
      font.underline: (modelData[4] & 8) !== 0
    }
  }
}
