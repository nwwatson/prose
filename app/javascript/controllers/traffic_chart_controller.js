import { Controller } from "@hotwired/stimulus"
import { renderBarChart, formatDayLabel } from "lib/svg_chart"

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

    renderBarChart(this.canvasTarget, entries, {
      formatLabel: formatDayLabel,
      minBarWidth: 4,
      labelInterval: Math.max(1, Math.floor(entries.length / 10))
    })
  }
}
