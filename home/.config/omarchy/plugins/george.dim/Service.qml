// Apple-style idle: after dimAfter seconds idle, fade a black layer over every
// screen; offAfter seconds later turn the screens off (DPMS). Only a click or a
// key wakes them (mouse/touchpad movement does not; see also
// misc.mouse_move_enables_dpms = false in ~/.config/hypr/input.lua). The waking
// click or key is swallowed. Never locks. Respects Omarchy's stay-awake toggle
// (Super + Ctrl + I) and idle inhibitors (video, calls).

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
  id: root

  // Injected by omarchy-shell's service loader.
  property var shell: null

  readonly property int dimAfter: 900      // seconds idle before dimming
  readonly property int offAfter: 30       // seconds after dimming before screens off
  readonly property real dimOpacity: 0.5
  readonly property int fadeInMs: 2000   // slow, like macOS display dim
  readonly property int fadeOutMs: 0     // instant return on wake

  property bool dimmed: false
  property bool screensOff: false

  function onIdle() {
    stayAwakeProbe.running = false
    stayAwakeProbe.running = true
  }

  function dim() {
    if (!idleMonitor.isIdle || root.dimmed) return
    root.dimmed = true
    offTimer.restart()
  }

  function wake() {
    offTimer.stop()
    stayAwakeProbe.running = false
    root.dimmed = false
    if (root.screensOff) {
      root.screensOff = false
      Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.dpms({ action = \"enable\" })"])
    }
  }

  IdleMonitor {
    id: idleMonitor
    enabled: true
    timeout: root.dimAfter
    respectInhibitors: true
    // Activity while dimmed (e.g. moving the mouse) is ignored: only a click
    // or key on the shade calls wake().
    onIsIdleChanged: {
      if (isIdle) root.onIdle()
      else if (!root.dimmed) stayAwakeProbe.running = false
    }
  }

  // Stay-awake is a flag file written by Omarchy's idle service.
  Process {
    id: stayAwakeProbe
    command: ["bash", "-c", "[[ -f $HOME/.local/state/omarchy/indicators/stay-awake ]] && echo yes || echo no"]
    stdout: SplitParser {
      onRead: function(line) { if (String(line).trim() === "no") root.dim() }
    }
  }

  Timer {
    id: offTimer
    interval: root.offAfter * 1000
    onTriggered: {
      if (!root.dimmed) return
      root.screensOff = true
      Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.dpms({ action = \"disable\" })"])
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: win
      required property var modelData
      screen: modelData

      property Region noInput: Region {}
      property Region allInput: Region { item: shade }

      visible: root.dimmed || shade.opacity > 0
      color: "transparent"
      anchors { top: true; bottom: true; left: true; right: true }
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "george-dim"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: root.dimmed ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
      // Pass-through while fading out; catch clicks and keys while dimmed.
      mask: root.dimmed ? allInput : noInput

      Rectangle {
        id: shade
        anchors.fill: parent
        color: "black"
        opacity: root.dimmed ? root.dimOpacity : 0
        // Slow fade in, short fade out on activity.
        Behavior on opacity {
          NumberAnimation { duration: root.dimmed ? root.fadeInMs : root.fadeOutMs; easing.type: Easing.InOutQuad }
        }
      }

      MouseArea {
        anchors.fill: parent
        enabled: root.dimmed
        acceptedButtons: Qt.AllButtons
        onPressed: function(mouse) { mouse.accepted = true; root.wake() }
        onWheel: function(wheel) { wheel.accepted = true }
      }

      Item {
        anchors.fill: parent
        focus: root.dimmed
        Keys.onPressed: function(event) { event.accepted = true; root.wake() }
      }
    }
  }
}
