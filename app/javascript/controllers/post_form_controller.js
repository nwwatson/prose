import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="post-form"
export default class extends Controller {
  static targets = ["statusSelect", "scheduledField"]

  connect() {
    this.toggleScheduledField()
  }

  statusChanged() {
    this.toggleScheduledField()
  }

  toggleScheduledField() {
    if (this.statusSelectTarget.value === 'scheduled') {
      this.scheduledFieldTarget.style.display = 'block'
    } else {
      this.scheduledFieldTarget.style.display = 'none'
    }
  }
}