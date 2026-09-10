import { Controller } from "@hotwired/stimulus"
import { loadTwitterWidgets } from "lib/twitter_widgets"

export default class extends Controller {
  connect() {
    if (this.element.querySelector(".twitter-tweet")) {
      loadTwitterWidgets().then(widgets => widgets.load(this.element))
    }
  }
}
