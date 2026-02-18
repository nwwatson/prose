import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "status"]

  check() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.fetchAvailability(), 300)
  }

  async fetchAvailability() {
    const handle = this.inputTarget.value.trim()
    if (handle.length < 3) {
      this.statusTarget.textContent = ""
      return
    }

    const response = await fetch(`/handle_availability?handle=${encodeURIComponent(handle)}`, {
      headers: { "Accept": "application/json" }
    })
    const data = await response.json()

    this.statusTarget.textContent = data.available ? "Available" : "Taken"
    this.statusTarget.className = data.available
      ? "text-sm text-green-600"
      : "text-sm text-red-600"
  }
}
