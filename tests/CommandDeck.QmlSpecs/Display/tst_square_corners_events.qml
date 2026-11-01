import QtQuick
import QtTest
import "../../../qml/common" as CommandDeck

// decoration:rounding 0 reaches CommandDeck as a theme radius of 0, and asks
// for square corners on cards, fields, keys, and pills alike.
Item {
  id: scene
  width: 400
  height: 300

  QtObject {
    id: squareTokens
    property int radius: 0
    property real scale: 1
    property string fontFamily: "monospace"
    property int panelPadding: 14
    property int rowPaddingX: 12
    property int gap: 8
    property int fontCaption: 10
    property int fontSmall: 11
    property int fontBody: 12
    property int fontSubtitle: 13
    property int fontTitle: 14
    property int fontHeading: 16
  }

  CommandDeck.Theme { id: rounded; loadShellTokens: false }
  CommandDeck.Theme { id: square; loadShellTokens: false; tokens: squareTokens }

  CommandDeck.SettingsCard { id: card; theme: square; title: "Card" }
  CommandDeck.KeyCap { id: key; theme: square; label: "K" }
  CommandDeck.DeckButton { id: button; theme: square; text: "Button" }
  CommandDeck.DeckButton { id: roundedButton; theme: rounded; text: "Button" }

  TestCase {
    name: "CommandDeck_square_corners"
    when: windowShown

    function test_rounding_zero_is_square_and_other_themes_keep_their_shape() {
      compare(square.radius, 0)
      compare(square.radiusSmall, 0)
      verify(rounded.radius > 0)
    }

    function test_controls_lose_their_minimum_corner() {
      compare(key.radius, 0)
      compare(button.background.radius, 0)
      compare(findChild(card, "settingsCardSurface").radius, 0)
      compare(roundedButton.background.radius, roundedButton.background.height / 2)
    }
  }
}
