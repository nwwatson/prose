import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sentinel", "loading"]

  connect() {
    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            this.loadMore()
          }
        })
      },
      { rootMargin: "200px" }
    )

    if (this.hasSentinelTarget) {
      this.observer.observe(this.sentinelTarget)
    }
  }

  sentinelTargetConnected(target) {
    this.observer?.observe(target)
  }

  disconnect() {
    this.observer?.disconnect()
  }

  loadMore() {
    const link = this.sentinelTarget.querySelector("a")
    if (link) {
      if (this.hasLoadingTarget) {
        this.loadingTarget.classList.remove("hidden")
      }
      link.click()
    }
  }
}
