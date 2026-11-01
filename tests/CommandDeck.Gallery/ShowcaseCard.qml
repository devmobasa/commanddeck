pragma ComponentBehavior: Bound
import QtQuick

// Shared title/chapter typography and the footage-only caption variant.
Item {
  id: card
  property bool captionMode: false
  property bool titleCard: false
  property string heading: ""
  property string detail: ""
  property string number: ""
  property string fontFamily: "sans-serif"
  property real inkOpacity: 1
  function fits() {
    return captionMode ? captionRow.implicitWidth <= width - 48 : titleStack.height <= height - 100
  }
  Rectangle {
    anchors.fill: parent
    visible: !card.captionMode
    gradient: Gradient {
      GradientStop { position: 0; color: "#0e1626" }
      GradientStop { position: 1; color: "#111a2b" }
    }
  }
  Column {
    id: titleStack
    visible: !card.captionMode
    anchors.centerIn: parent
    width: parent.width - 100
    spacing: 24
    opacity: card.inkOpacity
    Text {
      width: parent.width
      text: card.titleCard ? "CommandDeck" : card.number
      horizontalAlignment: Text.AlignHCenter
      color: "#8b9bb1"
      font.family: card.fontFamily
      font.pixelSize: 22
    }
    Text {
      width: parent.width
      text: card.heading
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.WordWrap
      color: "#f5f7fb"
      font.family: card.fontFamily
      font.pixelSize: 44
      font.weight: Font.DemiBold
    }
    Text {
      width: parent.width
      text: card.detail
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.WordWrap
      color: "#5b9cf5"
      font.family: card.fontFamily
      font.pixelSize: 24
      font.weight: Font.DemiBold
    }
  }
  Rectangle {
    visible: card.captionMode
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 86
    color: "#111a2b"
    Row {
      id: captionRow
      anchors.centerIn: parent
      spacing: 20
      Rectangle {
        width: keyText.implicitWidth + 28
        height: 42
        radius: 9
        color: "#22324b"
        border.color: "#415777"
        Text {
          id: keyText
          anchors.centerIn: parent
          text: card.detail
          font.family: card.fontFamily
          font.pixelSize: 22
          font.weight: Font.DemiBold
          color: "#80b2fa"
        }
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: card.heading
        color: "#f5f7fb"
        font.family: card.fontFamily
        font.pixelSize: 24
        font.weight: Font.DemiBold
      }
    }
  }
}
