import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (this.element.querySelector(".twitter-tweet")) {
      this.loadAndRender()
    }
  }

  loadAndRender() {
    if (window.twttr?.widgets) {
      window.twttr.widgets.load(this.element)
    } else {
      const script = document.createElement("script")
      script.src = "https://platform.twitter.com/widgets.js"
      script.onload = () => window.twttr.widgets.load(this.element)
      document.head.appendChild(script)
    }
  }
}
