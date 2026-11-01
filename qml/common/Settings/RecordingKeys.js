.pragma library

function chord(event) {
  const key = event.key
  if ([Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_Meta, Qt.Key_AltGr,
      Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_Hyper_L, Qt.Key_Hyper_R].indexOf(key) >= 0) return ""
  const modifiers = event.modifiers & (Qt.MetaModifier | Qt.ControlModifier | Qt.AltModifier | Qt.ShiftModifier)
  const special = ({})
  special[Qt.Key_Space] = "Space"
  special[Qt.Key_Return] = "Return"
  special[Qt.Key_Enter] = "KP_Enter"
  special[Qt.Key_Escape] = "Escape"
  special[Qt.Key_Backspace] = "BackSpace"
  special[Qt.Key_Delete] = "Delete"
  special[Qt.Key_Left] = "Left"
  special[Qt.Key_Right] = "Right"
  special[Qt.Key_Up] = "Up"
  special[Qt.Key_Down] = "Down"
  special[Qt.Key_Home] = "Home"
  special[Qt.Key_End] = "End"
  special[Qt.Key_PageUp] = "Prior"
  special[Qt.Key_PageDown] = "Next"
  special[Qt.Key_Insert] = "Insert"
  special[Qt.Key_Comma] = "comma"
  special[Qt.Key_Period] = "period"
  special[Qt.Key_Slash] = "slash"
  special[Qt.Key_Backslash] = "backslash"
  special[Qt.Key_Minus] = "minus"
  special[Qt.Key_Equal] = "equal"
  special[Qt.Key_Plus] = "plus"
  special[Qt.Key_BracketLeft] = "bracketleft"
  special[Qt.Key_BracketRight] = "bracketright"
  special[Qt.Key_Semicolon] = "semicolon"
  special[Qt.Key_Apostrophe] = "apostrophe"
  special[Qt.Key_QuoteLeft] = "grave"
  special[Qt.Key_Exclam] = "exclam"
  special[Qt.Key_QuoteDbl] = "quotedbl"
  special[Qt.Key_NumberSign] = "numbersign"
  special[Qt.Key_Dollar] = "dollar"
  special[Qt.Key_Percent] = "percent"
  special[Qt.Key_Ampersand] = "ampersand"
  special[Qt.Key_ParenLeft] = "parenleft"
  special[Qt.Key_ParenRight] = "parenright"
  special[Qt.Key_Asterisk] = "asterisk"
  special[Qt.Key_Colon] = "colon"
  special[Qt.Key_Less] = "less"
  special[Qt.Key_Greater] = "greater"
  special[Qt.Key_Question] = "question"
  special[Qt.Key_At] = "at"
  special[Qt.Key_AsciiCircum] = "asciicircum"
  special[Qt.Key_Underscore] = "underscore"
  special[Qt.Key_AsciiTilde] = "asciitilde"
  special[Qt.Key_BraceLeft] = "braceleft"
  special[Qt.Key_BraceRight] = "braceright"
  special[Qt.Key_Bar] = "bar"
  special[Qt.Key_Pause] = "Pause"
  special[Qt.Key_Print] = "Print"
  special[Qt.Key_SysReq] = "Sys_Req"
  special[Qt.Key_Clear] = "Clear"
  special[Qt.Key_Menu] = "Menu"
  special[Qt.Key_CapsLock] = "Caps_Lock"
  special[Qt.Key_NumLock] = "Num_Lock"
  special[Qt.Key_ScrollLock] = "Scroll_Lock"
  const media = ({})
  media[Qt.Key_VolumeUp] = "XF86AudioRaiseVolume"
  media[Qt.Key_VolumeDown] = "XF86AudioLowerVolume"
  media[Qt.Key_VolumeMute] = "XF86AudioMute"
  media[Qt.Key_MediaPlay] = "XF86AudioPlay"
  media[Qt.Key_MediaPause] = "XF86AudioPause"
  media[Qt.Key_MediaStop] = "XF86AudioStop"
  media[Qt.Key_MediaNext] = "XF86AudioNext"
  media[Qt.Key_MediaPrevious] = "XF86AudioPrev"
  media[Qt.Key_MonBrightnessUp] = "XF86MonBrightnessUp"
  media[Qt.Key_MonBrightnessDown] = "XF86MonBrightnessDown"
  media[Qt.Key_MicMute] = "XF86AudioMicMute"
  media[Qt.Key_MediaRecord] = "XF86AudioRecord"
  media[Qt.Key_MediaTogglePlayPause] = "XF86AudioPlay"
  media[Qt.Key_LaunchMedia] = "XF86AudioMedia"
  media[Qt.Key_AudioRewind] = "XF86AudioRewind"
  media[Qt.Key_AudioForward] = "XF86AudioForward"
  media[Qt.Key_AudioRepeat] = "XF86AudioRepeat"
  media[Qt.Key_AudioRandomPlay] = "XF86AudioRandomPlay"
  media[Qt.Key_AudioCycleTrack] = "XF86AudioCycleTrack"
  media[Qt.Key_Eject] = "XF86Eject"
  media[Qt.Key_KeyboardLightOnOff] = "XF86KbdLightOnOff"
  media[Qt.Key_KeyboardBrightnessUp] = "XF86KbdBrightnessUp"
  media[Qt.Key_KeyboardBrightnessDown] = "XF86KbdBrightnessDown"
  const functionKey = key >= Qt.Key_F1 && key <= Qt.Key_F24
  if (!modifiers && !functionKey && !media[key]) return ""
  let name = functionKey ? "F" + (key - Qt.Key_F1 + 1) : media[key] || special[key]
    || (key >= Qt.Key_0 && key <= Qt.Key_Z ? String.fromCharCode(key) : "")
    || (event.nativeScanCode > 0 && event.nativeScanCode < 10000 ? "code:" + event.nativeScanCode : "")
  if (event.modifiers & Qt.KeypadModifier) {
    const keypadNames = {Return: "KP_Enter", Left: "KP_Left", Right: "KP_Right", Up: "KP_Up", Down: "KP_Down",
      Home: "KP_Home", End: "KP_End", Prior: "KP_Prior", Next: "KP_Next", Insert: "KP_Insert", Delete: "KP_Delete",
      slash: "KP_Divide", asterisk: "KP_Multiply", minus: "KP_Subtract", plus: "KP_Add", period: "KP_Decimal", comma: "KP_Decimal", equal: "KP_Equal"}
    name = key >= Qt.Key_0 && key <= Qt.Key_9 ? "KP_" + String.fromCharCode(key) : keypadNames[name] || name
  }
  if (!name) return ""
  const parts = []
  if (modifiers & Qt.MetaModifier) parts.push("Super")
  if (modifiers & Qt.ControlModifier) parts.push("Ctrl")
  if (modifiers & Qt.AltModifier) parts.push("Alt")
  if (modifiers & Qt.ShiftModifier) parts.push("Shift")
  return parts.concat([name]).join("+")
}
