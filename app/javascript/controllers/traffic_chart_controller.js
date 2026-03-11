import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    data: Object
  }

  connect() {
    this.draw()
  }

  draw() {
    const entries = Object.entries(this.dataValue)
    const container = this.canvasTarget

    if (entries.length === 0) {
      container.innerHTML = ""
      return
    }

    const values = entries.map(([, v]) => v)
    const labels = entries.map(([k]) => this.formatDate(k))
    const max = Math.max(...values, 1)

    const width = container.offsetWidth || 600
    const height = 300
    const paddingTop = 20
    const paddingBottom = 40
    const paddingLeft = 50
    const paddingRight = 20
    const chartWidth = width - paddingLeft - paddingRight
    const chartHeight = height - paddingTop - paddingBottom

    const barWidth = Math.max(Math.min(chartWidth / entries.length * 0.7, 40), 4)
    const barGap = chartWidth / entries.length

    const ns = "http://www.w3.org/2000/svg"
    const svg = document.createElementNS(ns, "svg")
    svg.setAttribute("viewBox", `0 0 ${width} ${height}`)
    svg.setAttribute("class", "w-full")
    svg.style.height = `${height}px`

    // Y-axis gridlines and labels
    const gridLines = 4
    for (let i = 0; i <= gridLines; i++) {
      const y = paddingTop + (chartHeight / gridLines) * i
      const value = Math.round(max - (max / gridLines) * i)

      const line = document.createElementNS(ns, "line")
      line.setAttribute("x1", paddingLeft)
      line.setAttribute("x2", width - paddingRight)
      line.setAttribute("y1", y)
      line.setAttribute("y2", y)
      line.setAttribute("stroke", "#e5e7eb")
      line.setAttribute("stroke-width", "1")
      svg.appendChild(line)

      const text = document.createElementNS(ns, "text")
      text.setAttribute("x", paddingLeft - 8)
      text.setAttribute("y", y + 4)
      text.setAttribute("text-anchor", "end")
      text.setAttribute("class", "text-xs")
      text.setAttribute("fill", "#9ca3af")
      text.setAttribute("font-size", "11")
      text.textContent = value
      svg.appendChild(text)
    }

    // Bars
    entries.forEach(([, v], i) => {
      const barHeight = max > 0 ? (v / max) * chartHeight : 0
      const x = paddingLeft + i * barGap + (barGap - barWidth) / 2
      const y = paddingTop + chartHeight - barHeight

      const rect = document.createElementNS(ns, "rect")
      rect.setAttribute("x", x)
      rect.setAttribute("y", y)
      rect.setAttribute("width", barWidth)
      rect.setAttribute("height", barHeight)
      rect.setAttribute("rx", Math.min(barWidth / 4, 4))
      rect.setAttribute("fill", "#2563eb")

      const title = document.createElementNS(ns, "title")
      title.textContent = `${labels[i]}: ${v}`
      rect.appendChild(title)

      svg.appendChild(rect)
    })

    // X-axis labels (show subset to avoid overlap)
    const labelInterval = Math.max(1, Math.floor(entries.length / 10))
    entries.forEach(([, ], i) => {
      if (i % labelInterval !== 0 && i !== entries.length - 1) return

      const x = paddingLeft + i * barGap + barGap / 2
      const y = height - 10

      const text = document.createElementNS(ns, "text")
      text.setAttribute("x", x)
      text.setAttribute("y", y)
      text.setAttribute("text-anchor", "middle")
      text.setAttribute("fill", "#9ca3af")
      text.setAttribute("font-size", "11")
      text.textContent = labels[i]
      svg.appendChild(text)
    })

    container.replaceChildren(svg)
  }

  formatDate(key) {
    const parts = key.split("-")
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    return `${months[parseInt(parts[1]) - 1]} ${parseInt(parts[2])}`
  }
}
