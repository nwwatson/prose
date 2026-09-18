import { Controller } from "@hotwired/stimulus"
import { readingList } from "lib/reading_list"

// Loads an anonymous reader's saved posts on the reading list page. Their ids
// only exist in localStorage, so the page asks the server to render cards for
// them. Signed-in readers' lists are rendered server-side and skip this.
export default class extends Controller {
  static targets = [ "frame" ]
  static values = { url: String }

  connect() {
    if (readingList.mode !== "local") return

    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("ids", readingList.ids().join(","))
    this.frameTarget.src = url.toString()
  }
}
