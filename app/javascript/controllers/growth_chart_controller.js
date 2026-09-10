import { Controller } from "@hotwired/stimulus"
import { renderBarChart, formatMonthLabel } from "lib/svg_chart"

export default class extends Controller {
  static targets = ["canvas", "monthlyBtn", "cumulativeBtn"]
  static classes = ["active", "inactive"]
  static values = {
    monthly: Object,
    cumulative: Object
  }

  connect() {
    this.mode = "monthly"
    this.draw()
  }

  showMonthly() {
    this.mode = "monthly"
    this.updateButtons()
    this.draw()
  }

  showCumulative() {
    this.mode = "cumulative"
    this.updateButtons()
    this.draw()
  }

  updateButtons() {
    const activeBtn = this.mode === "monthly" ? this.monthlyBtnTarget : this.cumulativeBtnTarget
    const inactiveBtn = this.mode === "monthly" ? this.cumulativeBtnTarget : this.monthlyBtnTarget

    activeBtn.classList.remove(...this.inactiveClasses)
    activeBtn.classList.add(...this.activeClasses)
    inactiveBtn.classList.remove(...this.activeClasses)
    inactiveBtn.classList.add(...this.inactiveClasses)
  }

  draw() {
    const data = this.mode === "monthly" ? this.monthlyValue : this.cumulativeValue

    renderBarChart(this.canvasTarget, Object.entries(data), {
      formatLabel: formatMonthLabel,
      minBarWidth: 8
    })
  }
}
