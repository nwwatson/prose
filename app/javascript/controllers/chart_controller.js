import { Controller } from "@hotwired/stimulus"

// Simple SVG sparkline chart (no external dependencies)
export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    data: Object,
    type: { type: String, default: "line" }
  }

  connect() {
    this.draw()
  }

  draw() {
    const data = this.dataValue
    const entries = Object.entries(data)
    if (entries.length === 0) return

    const canvas = this.canvasTarget
    const values = entries.map(([, v]) => v)
    const max = Math.max(...values, 1)
    const width = canvas.parentElement.offsetWidth || 400
    const height = 200
    const padding = 20

    const points = values.map((v, i) => {
      const x = padding + (i / Math.max(values.length - 1, 1)) * (width - padding * 2)
      const y = height - padding - (v / max) * (height - padding * 2)
      return `${x},${y}`
    })

    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg")
    svg.setAttribute("viewBox", `0 0 ${width} ${height}`)
    svg.setAttribute("class", "w-full")
    svg.style.height = `${height}px`

    // Line
    const polyline = document.createElementNS("http://www.w3.org/2000/svg", "polyline")
    polyline.setAttribute("points", points.join(" "))
    polyline.setAttribute("fill", "none")
    polyline.setAttribute("stroke", "#4f46e5")
    polyline.setAttribute("stroke-width", "2")
    svg.appendChild(polyline)

    // Area fill
    const area = document.createElementNS("http://www.w3.org/2000/svg", "polygon")
    const areaPoints = [
      `${padding},${height - padding}`,
      ...points,
      `${padding + ((values.length - 1) / Math.max(values.length - 1, 1)) * (width - padding * 2)},${height - padding}`
    ]
    area.setAttribute("points", areaPoints.join(" "))
    area.setAttribute("fill", "rgba(79, 70, 229, 0.1)")
    svg.appendChild(area)

    canvas.replaceWith(svg)
  }
}
