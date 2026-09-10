// Timer helpers for Stimulus controllers.
//
// Every timeout scheduled through these helpers is tracked so it can be
// cancelled when a controller disconnects — an untracked setTimeout survives
// Turbo navigation and keeps firing against a detached controller.

// Wraps fn so it only runs once ms have passed without another call.
// The returned function exposes `.cancel()` to drop a pending run.
export function debounce(fn, ms) {
  let timer = null

  const debounced = (...args) => {
    clearTimeout(timer)
    timer = setTimeout(() => {
      timer = null
      fn(...args)
    }, ms)
  }

  debounced.cancel = () => {
    clearTimeout(timer)
    timer = null
  }

  return debounced
}

// Returns a timeout tracker bound to a controller instance. Call `clearAll()`
// from the controller's disconnect() to cancel everything still pending.
//
//   connect() { this.timeouts = useTimeouts(this) }
//   disconnect() { this.timeouts.clearAll() }
//   somewhere() { this.timeouts.set(() => this.retry(), 5000) }
export function useTimeouts() {
  const ids = new Set()

  return {
    set(fn, ms) {
      const id = setTimeout(() => {
        ids.delete(id)
        fn()
      }, ms)
      ids.add(id)
      return id
    },

    clear(id) {
      if (id == null) return
      clearTimeout(id)
      ids.delete(id)
    },

    clearAll() {
      ids.forEach(id => clearTimeout(id))
      ids.clear()
    }
  }
}
