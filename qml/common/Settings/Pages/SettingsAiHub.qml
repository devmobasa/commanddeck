import "../.."
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../UiConstants.js" as Ui
import "../../Protocol.js" as Protocol

ColumnLayout {
  id: hub
  required property var host
  property string section: Ui.AiHubSection.Assistant
  onSectionChanged: Qt.callLater(host.maybeRefreshAgentModels)
  readonly property alias assistantPage: assistantScroll
  readonly property alias aiPage: quickAnswersScroll
  readonly property alias part_aiFeaturesCard: aiFeaturesCard
  readonly property alias part_aiFeaturesToggle: aiFeaturesToggle
  spacing: Math.round(12 * host.theme.scale)

  function selectSearchSection() {
    const query = host.part_settingsSearch.text.trim()
    if (query.length === 0 || !host.aiFeaturesEnabled) return
    const assistantMatch = host.pageCards.assistant.some(card => card && card.matchesSearch)
    const quickMatch = host.pageCards.quickAnswers.some(card => card && card.matchesSearch)
    if (assistantMatch && !quickMatch) section = Ui.AiHubSection.Assistant
    else if (quickMatch && !assistantMatch) section = Ui.AiHubSection.QuickAnswers
  }

  function resetScroll() {
    const assistantViewport = assistantScroll.contentItem as Flickable
    const quickViewport = quickAnswersScroll.contentItem as Flickable
    assistantViewport.contentY = 0
    quickViewport.contentY = 0
  }

  function forwardWheel(event) {
    const scroll = hub.section === Ui.AiHubSection.Assistant ? assistantScroll : quickAnswersScroll
    const viewport = scroll.contentItem as Flickable
    const rawDelta = event.pixelDelta.y !== 0
      ? event.pixelDelta.y : event.angleDelta.y / 120 * 60 * hub.host.theme.scale
    const delta = event.inverted ? -rawDelta : rawDelta
    const maximum = Math.max(0, viewport.contentHeight - viewport.height)
    viewport.contentY = Math.max(0, Math.min(maximum, viewport.contentY - delta))
    event.accepted = true
  }

  Connections {
    target: hub.host.part_settingsSearch
    function onTextChanged() { Qt.callLater(hub.selectSearchSection) }
  }

  SettingsCard {
    id: aiFeaturesCard
    Layout.fillWidth: true
    wheelForwarder: hub.forwardWheel
    searchQuery: hub.host.part_settingsSearch.text
    settingId: Protocol.SettingIds.AiFeatures
    theme: hub.host.theme
    title: "AI features"
    description: "One switch for the assistant and quick answers. Both send requests only when you ask."

    SettingsToggle {
      id: aiFeaturesToggle
      theme: hub.host.theme
      Layout.fillWidth: true
      text: "Enable AI features"
      help: "Off hides both sections and turns direct AI off."
      checked: hub.host.aiFeaturesEnabled
      Accessible.name: "Enable AI features"
      onToggled: hub.host.aiFeaturesToggled(checked)
    }

    Text {
      visible: !hub.host.aiFeaturesEnabled
      Layout.fillWidth: true
      text: "AI features are off. Turn them on to use the assistant or quick answers."
      wrapMode: Text.Wrap
      color: hub.host.theme.textMuted
      font.family: hub.host.theme.fontFamily
      font.pixelSize: hub.host.theme.fontBody
      Accessible.role: Accessible.StaticText
      Accessible.name: text
    }
  }

  SettingsSegmented {
    id: sectionSwitcher
    Layout.alignment: Qt.AlignLeft
    visible: hub.host.aiFeaturesEnabled
    theme: hub.host.theme
    tabPerSegment: true
    Accessible.name: "AI section"
    showCurrentDescription: false
    options: [
      { id: Ui.AiHubSection.Assistant, title: "Assistant", objectName: "aiAssistantSection",
        accessibleName: "Assistant settings", description: "Signed-in conversations, models, and tool permissions" },
      { id: Ui.AiHubSection.QuickAnswers, title: "Quick answers", objectName: "aiQuickSection",
        accessibleName: "Quick answer settings", description: "Direct providers and one-question answers" }
    ]
    Component.onCompleted: currentIndex = hub.section === Ui.AiHubSection.Assistant ? 0 : 1
    Connections {
      target: hub
      function onSectionChanged() { sectionSwitcher.currentIndex = hub.section === Ui.AiHubSection.Assistant ? 0 : 1 }
    }
    onActivated: index => hub.section = options[index].id
    WheelHandler {
      target: null
      onWheel: event => hub.forwardWheel(event)
    }
  }

  StackLayout {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: hub.host.aiFeaturesEnabled
    currentIndex: hub.section === Ui.AiHubSection.Assistant ? 0 : 1

    SettingsAssistantPage {
      id: assistantScroll
      host: hub.host
    }

    SettingsAiPage {
      id: quickAnswersScroll
      host: hub.host
    }
  }
}
