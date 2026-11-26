import { Controller } from "@hotwired/stimulus"
import { useTimeouts } from "lib/timers"

export default class extends Controller {
  connect() {
    this.timeouts = useTimeouts()
  }

  disconnect() {
    this.timeouts.clearAll()
  }

  scrollTo(event) {
    event.preventDefault()

    const href = event.currentTarget.getAttribute("href")
    const targetId = href.replace("#", "")
    const target = document.getElementById(targetId)

    if (!target) return

    target.scrollIntoView({ behavior: "smooth", block: "start" })

    // Update URL hash without jumping
    history.pushState(null, "", href)

    // Apply highlight after scroll completes
    this.timeouts.set(() => this.highlight(target), 300)
  }

  highlight(element) {
    element.classList.add("toc-highlight")
    this.timeouts.set(() => element.classList.remove("toc-highlight"), 2000)
  }
}
