import { Controller } from "@hotwired/stimulus"
import { requestJSON } from "lib/request"
import { debounce } from "lib/timers"

export default class extends Controller {
  static targets = ["input", "status"]
  static values = { url: String, available: String, taken: String }

  connect() {
    this.abortController = null
    this.debouncedCheck = debounce(() => this.fetchAvailability(), 300)
  }

  disconnect() {
    this.debouncedCheck.cancel()
    this.abortController?.abort()
    this.abortController = null
  }

  check() {
    // Abort the in-flight request too, so a slow earlier response can't
    // overwrite the result for what the user has typed since.
    this.abortController?.abort()
    this.abortController = null
    this.debouncedCheck()
  }

  async fetchAvailability() {
    const handle = this.inputTarget.value.trim()
    if (handle.length < 3) {
      this.statusTarget.textContent = ""
      return
    }

    const controller = new AbortController()
    this.abortController = controller

    try {
      const url = `${this.urlValue}?${new URLSearchParams({ handle })}`
      const data = await requestJSON(url, { signal: controller.signal })

      // A newer check superseded this one while it was in flight.
      if (this.abortController !== controller) return

      this.statusTarget.textContent = data.available ? this.availableValue : this.takenValue
      this.statusTarget.className = data.available
        ? "text-sm text-green-600"
        : "text-sm text-red-600"
    } catch (error) {
      if (error.name !== "AbortError") throw error
    } finally {
      if (this.abortController === controller) this.abortController = null
    }
  }
}
