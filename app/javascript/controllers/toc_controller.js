import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
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
    setTimeout(() => this.highlight(target), 300)
  }

  highlight(element) {
    element.classList.add("toc-highlight")
    setTimeout(() => element.classList.remove("toc-highlight"), 2000)
  }
}
