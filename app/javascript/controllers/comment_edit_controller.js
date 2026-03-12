import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { commentId: Number }

  toggle() {
    const editForm = document.getElementById(`edit_comment_${this.commentIdValue}`)
    if (editForm) {
      editForm.classList.toggle("hidden")
    }
  }
}
