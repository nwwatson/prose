// Loads the Twitter/X widgets.js script at most once per page, however many
// tweet embeds are on it, and memoizes the load so late-arriving embeds can
// still await it.

let widgetsPromise = null

export function loadTwitterWidgets() {
  if (window.twttr?.widgets) return Promise.resolve(window.twttr.widgets)

  if (!widgetsPromise) {
    widgetsPromise = new Promise((resolve, reject) => {
      const script = document.createElement("script")
      script.src = "https://platform.twitter.com/widgets.js"
      script.onload = () => resolve(window.twttr.widgets)
      script.onerror = reject
      document.head.appendChild(script)
    })
  }

  return widgetsPromise
}
