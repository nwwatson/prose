import { Controller } from "@hotwired/stimulus"
import { request } from "lib/request"

// Shows how many subscribers the segment chosen in a <select> matches, fetched
// from segments#count so only that one segment is counted. Each segment option
// carries its URL in `data-count-url`.
export default class extends Controller {
  static targets = ["select", "output"]

  connect() {
    this.refresh()
  }

  async refresh() {
    const url = this.selectTarget.selectedOptions[0]?.dataset.countUrl
    this.url = url
    this.outputTarget.hidden = true
    if (!url) return

    const response = await request(url, { accept: "text/html" })
    if (!response.ok) return

    const html = await response.text()
    // The selection may have changed while this one was loading.
    if (this.url !== url) return

    this.outputTarget.innerHTML = html
    this.outputTarget.hidden = false
  }
}
