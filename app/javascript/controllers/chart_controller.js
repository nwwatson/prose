import { Controller } from "@hotwired/stimulus"
import { renderSparkline } from "lib/svg_chart"

// Simple SVG sparkline chart (no external dependencies)
export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    data: Object
  }

  connect() {
    this.draw()
  }

  draw() {
    const values = Object.values(this.dataValue)
    renderSparkline(this.canvasTarget, values)
  }
}
