.pragma library
.import "components/Protocol.js" as Protocol

// Herdr rows in the shapes HerdrProvider sends, built from the spaces and tabs
// of a Herdr*Data.js capture. `icon` is the stage's resolved terminal icon.

// The built-in filters, with Herdr's spaces and tabs as their own tokens.
function filters(builtIn) {
  return builtIn.filter(function(filter) { return filter.id !== "herdr" }).concat([
    { id: "herdr", label: "Herdr", token: "herdr:", aliases: [] },
    { id: "herdr-spaces", label: "Herdr spaces", token: "hspace:", aliases: ["herdr-space:", "hspaces:"] },
    { id: "herdr-tabs", label: "Herdr tabs", token: "htab:", aliases: ["herdr-tab:", "htabs:"] }
  ])
}

function plural(count, noun) {
  return count + " " + noun + (count === 1 ? "" : "s")
}

function spaceTabs(tabs, workspaceId) {
  return tabs
    .filter(function(tab) { return tab.workspaceId === workspaceId })
    .sort(function(left, right) { return left.number - right.number })
}

function spaceRow(space, tabs, icon) {
  const number = String(space.number)
  const details = [
    { label: "Number", value: number },
    { label: "Tabs", value: String(space.tabs) },
    { label: "Panes", value: String(space.panes) }
  ]
  if (space.status.length > 0) details.push({ label: "Agent status", value: space.status })
  details.push({ label: "Herdr ID", value: space.id, monospace: true })
  for (const tab of spaceTabs(tabs, space.id).slice(0, 8)) {
    details.push({ label: tab.label || "Tab " + tab.number,
      value: plural(tab.panes, "pane") + (tab.status.length > 0 ? " · " + tab.status : "") })
  }

  return {
    id: "herdr:workspace:" + space.id, kind: Protocol.ResultKinds.Workspace, sourceId: "herdr", providerId: "herdr",
    icon: icon, title: space.label || "Space " + number,
    subtitle: "Space " + number + " · " + plural(space.tabs, "tab") + " · " + plural(space.panes, "pane")
      + (space.focused ? " · focused" : ""),
    details: details,
    metadata: {
      herdrTargetKind: "workspace", herdrTargetId: space.id, herdrWorkspaceId: space.id,
      herdrWorkspaceLabel: space.label, herdrFocused: space.focused ? "true" : "false", herdrAgentStatus: space.status
    },
    actions: [
      { id: "switch-space", title: "Switch Herdr Space", kind: Protocol.ActionKinds.HerdrFocus,
        arguments: { targetKind: "workspace", targetId: space.id } },
      { id: "browse-tabs", title: "Browse tabs", kind: Protocol.ActionKinds.BrowseHerdrTabs,
        arguments: { targetId: space.id } },
      { id: "new-tab", title: "New tab in this space", kind: Protocol.ActionKinds.HerdrCreateTab,
        arguments: { targetId: space.id }, inputs: [{ name: "name", defaultValue: "New tab" }] }
    ]
  }
}

function tabRow(tab, space, icon) {
  const number = String(tab.number)
  const details = [
    { label: "Space", value: space.label },
    { label: "Number", value: number },
    { label: "Panes", value: String(tab.panes) }
  ]
  if (tab.status.length > 0) details.push({ label: "Agent status", value: tab.status })
  details.push({ label: "Herdr ID", value: tab.id, monospace: true })

  return {
    id: "herdr:tab:" + tab.id, kind: Protocol.ResultKinds.Tab, sourceId: "herdr", providerId: "herdr",
    icon: icon, title: tab.label || "Tab " + number,
    subtitle: "In " + space.label + " · Tab " + number + " · " + plural(tab.panes, "pane")
      + (tab.focused ? " · focused" : ""),
    details: details,
    metadata: {
      herdrTargetKind: "tab", herdrTargetId: tab.id, herdrWorkspaceId: tab.workspaceId,
      herdrWorkspaceLabel: space.label, herdrFocused: tab.focused ? "true" : "false", herdrAgentStatus: tab.status
    },
    actions: [
      { id: "switch-tab", title: "Switch Herdr Tab", kind: Protocol.ActionKinds.HerdrFocus,
        arguments: { targetKind: "tab", targetId: tab.id } },
      { id: "rename-tab", title: "Rename tab", kind: Protocol.ActionKinds.HerdrRenameTab,
        arguments: { targetId: tab.id }, inputs: [{ name: "name", defaultValue: tab.label }] }
    ]
  }
}

// An empty Herdr scope's order: focused first, then spaces before tabs, space
// number, tab number.
function browse(spaces, tabs, icon, includeSpaces, includeTabs) {
  const candidates = []
  if (includeSpaces) {
    for (const space of spaces) {
      candidates.push({ row: spaceRow(space, tabs, icon), focused: space.focused, kind: 0,
        space: space.number, tab: 0 })
    }
  }
  if (includeTabs) {
    for (const tab of tabs) {
      const space = spaces.find(function(value) { return value.id === tab.workspaceId })
      candidates.push({ row: tabRow(tab, space, icon), focused: tab.focused, kind: 1,
        space: space.number, tab: tab.number })
    }
  }
  return candidates.sort(function(left, right) {
    return (right.focused - left.focused) || (left.kind - right.kind)
      || (left.space - right.space) || (left.tab - right.tab)
  }).map(function(candidate) { return candidate.row })
}
