import QtQuick

// Shared vector glyphs in a 24-unit box; no font fallback or icon theme.
Canvas {
  id: symbolCanvas
  property string symbol: "search"
  property color ink: "white"
  onSymbolChanged: requestPaint()
  onInkChanged: requestPaint()
  Accessible.ignored: true
  onPaint: {
    const ctx = getContext("2d")
    ctx.reset()
    ctx.scale(width / 24, height / 24)
    ctx.strokeStyle = ink
    ctx.fillStyle = ink
    ctx.lineWidth = 2.1
    ctx.lineCap = "round"
    ctx.lineJoin = "round"
    ctx.beginPath()
    switch (symbol) {
      case "search":
        ctx.arc(9.6, 9.6, 6.72, 0, 2 * Math.PI)
        ctx.moveTo(14.64, 14.64)
        ctx.lineTo(21.6, 21.6)
        break
      case "ai":
        ctx.moveTo(12, 2.5)
        ctx.quadraticCurveTo(14, 10, 21.5, 12)
        ctx.quadraticCurveTo(14, 14, 12, 21.5)
        ctx.quadraticCurveTo(10, 14, 2.5, 12)
        ctx.quadraticCurveTo(10, 10, 12, 2.5)
        ctx.fill()
        return
      case "editors":
        ctx.moveTo(4, 15)
        ctx.lineTo(15, 4)
        ctx.quadraticCurveTo(17, 2, 19, 4)
        ctx.lineTo(20, 5)
        ctx.quadraticCurveTo(22, 7, 20, 9)
        ctx.lineTo(9, 20)
        ctx.lineTo(3, 21)
        ctx.closePath()
        ctx.moveTo(14, 5)
        ctx.lineTo(19, 10)
        ctx.moveTo(4, 15)
        ctx.lineTo(9, 20)
        break
      case "filters":
        ctx.moveTo(3, 4)
        ctx.lineTo(21, 4)
        ctx.lineTo(14, 12)
        ctx.lineTo(14, 19)
        ctx.lineTo(10, 21)
        ctx.lineTo(10, 12)
        ctx.closePath()
        break
      case "shortcuts":
        ctx.translate(12, 12)
        ctx.scale(0.84, 0.84)
        ctx.translate(-12, -12)
        ctx.lineWidth = 2.1 / 0.84
        ctx.moveTo(8, 8)
        ctx.lineTo(5, 8)
        ctx.bezierCurveTo(1, 8, 1, 2, 5, 2)
        ctx.bezierCurveTo(8, 2, 8, 5, 8, 8)
        ctx.lineTo(16, 8)
        ctx.lineTo(16, 5)
        ctx.bezierCurveTo(16, 1, 22, 1, 22, 5)
        ctx.bezierCurveTo(22, 8, 19, 8, 16, 8)
        ctx.lineTo(16, 16)
        ctx.lineTo(19, 16)
        ctx.bezierCurveTo(23, 16, 23, 22, 19, 22)
        ctx.bezierCurveTo(16, 22, 16, 19, 16, 16)
        ctx.lineTo(8, 16)
        ctx.lineTo(8, 19)
        ctx.bezierCurveTo(8, 23, 2, 23, 2, 19)
        ctx.bezierCurveTo(2, 16, 5, 16, 8, 16)
        ctx.closePath()
        break
      case "customization":
        for (let point = 0; point < 10; point++) {
          const angle = -Math.PI / 2 + point * Math.PI / 5
          const radius = point % 2 === 0 ? 10 : 4.5
          const x = 12 + Math.cos(angle) * radius
          const y = 12 + Math.sin(angle) * radius
          if (point === 0) ctx.moveTo(x, y)
          else ctx.lineTo(x, y)
        }
        ctx.closePath()
        break
      case "diagnostics":
        ctx.arc(12, 12, 9, 0, 2 * Math.PI)
        ctx.moveTo(12, 11)
        ctx.lineTo(12, 17)
        ctx.moveTo(12, 7)
        ctx.lineTo(12, 7.2)
        break
    }
    ctx.stroke()
  }
}
