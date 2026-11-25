import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card", "input"]

  select(event) {
    const card = event.currentTarget
    const input = card.querySelector("input[type='radio']")
    if (!input) return

    input.checked = true
    input.dispatchEvent(new Event("change", { bubbles: true }))

    this.cardTargets.forEach(c => {
      c.classList.remove("border-blue-500", "ring-2", "ring-blue-500")
      c.classList.add("border-gray-200")
    })

    card.classList.remove("border-gray-200")
    card.classList.add("border-blue-500", "ring-2", "ring-blue-500")
  }
}
