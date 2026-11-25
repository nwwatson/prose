// Shared "did the user click outside this controller's element?" listener.
//
// Returns an observer rather than registering immediately so callers can scope
// the document listener to the time a dropdown is actually open, instead of
// keeping one alive for the controller's whole lifetime. `unobserve()` is
// idempotent, so calling it from both `close()` and `disconnect()` is safe.
export function useClickOutside(controller, { onClickOutside } = {}) {
  let observing = false

  const handler = (event) => {
    if (!controller.element.contains(event.target)) {
      onClickOutside(event)
    }
  }

  return {
    observe() {
      if (observing) return
      observing = true
      document.addEventListener("click", handler)
    },

    unobserve() {
      if (!observing) return
      observing = false
      document.removeEventListener("click", handler)
    }
  }
}
