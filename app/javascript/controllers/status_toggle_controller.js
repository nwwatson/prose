import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["publishedAt"]

  update(event) {
    if (event.target.value === "scheduled") {
      this.publishedAtTarget.classList.remove("hidden")
    } else {
      this.publishedAtTarget.classList.add("hidden")
    }
  }
}
