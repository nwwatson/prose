const SVG_NS = "http://www.w3.org/2000/svg"

const MONTH_NAMES = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

// Creates a namespaced SVG element, applying attrs and optional text content.
export function svgEl(name, attrs = {}, text) {
  const el = document.createElementNS(SVG_NS, name)
  for (const [key, value] of Object.entries(attrs)) {
    el.setAttribute(key, value)
  }
  if (text !== undefined) el.textContent = text
  return el
}

export function formatMonthLabel(key) {
  const [year, month] = key.split("-")
  return `${MONTH_NAMES[parseInt(month, 10) - 1]} '${year.slice(2)}`
}

export function formatDayLabel(key) {
  const [, month, day] = key.split("-")
  return `${MONTH_NAMES[parseInt(month, 10) - 1]} ${parseInt(day, 10)}`
}

// Renders a bar chart (gridlines, bars, x-axis labels) into container, replacing its contents.
// entries: array of [key, value] pairs.
export function renderBarChart(container, entries, { formatLabel, minBarWidth = 8, labelInterval = 1, height = 300 } = {}) {
  if (entries.length === 0) {
    container.replaceChildren()
    return
  }

  const values = entries.map(([, v]) => v)
  const labels = entries.map(([k]) => formatLabel(k))
  const max = Math.max(...values, 1)

  const width = container.offsetWidth || 600
  const paddingTop = 20
  const paddingBottom = 40
  const paddingLeft = 50
  const paddingRight = 20
  const chartWidth = width - paddingLeft - paddingRight
  const chartHeight = height - paddingTop - paddingBottom

  const barWidth = Math.max(Math.min((chartWidth / entries.length) * 0.7, 40), minBarWidth)
  const barGap = chartWidth / entries.length

  const svg = svgEl("svg", { viewBox: `0 0 ${width} ${height}`, class: "w-full" })
  svg.style.height = `${height}px`

  // Y-axis gridlines and labels
  const gridLines = 4
  for (let i = 0; i <= gridLines; i++) {
    const y = paddingTop + (chartHeight / gridLines) * i
    const value = Math.round(max - (max / gridLines) * i)

    svg.appendChild(svgEl("line", {
      x1: paddingLeft,
      x2: width - paddingRight,
      y1: y,
      y2: y,
      stroke: "#e5e7eb",
      "stroke-width": "1"
    }))

    svg.appendChild(svgEl("text", {
      x: paddingLeft - 8,
      y: y + 4,
      "text-anchor": "end",
      class: "text-xs",
      fill: "#9ca3af",
      "font-size": "11"
    }, value))
  }

  // Bars
  entries.forEach(([, v], i) => {
    const barHeight = max > 0 ? (v / max) * chartHeight : 0
    const x = paddingLeft + i * barGap + (barGap - barWidth) / 2
    const y = paddingTop + chartHeight - barHeight

    const rect = svgEl("rect", {
      x,
      y,
      width: barWidth,
      height: barHeight,
      rx: Math.min(barWidth / 4, 4),
      fill: "#2563eb"
    })
    rect.appendChild(svgEl("title", {}, `${labels[i]}: ${v}`))
    svg.appendChild(rect)
  })

  // X-axis labels (subset when labelInterval > 1, to avoid overlap)
  entries.forEach((_, i) => {
    if (i % labelInterval !== 0 && i !== entries.length - 1) return

    svg.appendChild(svgEl("text", {
      x: paddingLeft + i * barGap + barGap / 2,
      y: height - 10,
      "text-anchor": "middle",
      fill: "#9ca3af",
      "font-size": "11"
    }, labels[i]))
  })

  container.replaceChildren(svg)
}

// Renders a line sparkline with area fill into container, replacing its contents.
export function renderSparkline(container, values, { height = 200, padding = 20, stroke = "#4f46e5", fill = "rgba(79, 70, 229, 0.1)" } = {}) {
  if (values.length === 0) {
    container.replaceChildren()
    return
  }

  const width = container.offsetWidth || 400
  const max = Math.max(...values, 1)
  const span = Math.max(values.length - 1, 1)

  const points = values.map((v, i) => {
    const x = padding + (i / span) * (width - padding * 2)
    const y = height - padding - (v / max) * (height - padding * 2)
    return `${x},${y}`
  })

  const svg = svgEl("svg", { viewBox: `0 0 ${width} ${height}`, class: "w-full" })
  svg.style.height = `${height}px`

  svg.appendChild(svgEl("polyline", {
    points: points.join(" "),
    fill: "none",
    stroke,
    "stroke-width": "2"
  }))

  const areaPoints = [
    `${padding},${height - padding}`,
    ...points,
    `${padding + ((values.length - 1) / span) * (width - padding * 2)},${height - padding}`
  ]
  svg.appendChild(svgEl("polygon", { points: areaPoints.join(" "), fill }))

  container.replaceChildren(svg)
}
