// Guarded localStorage access.
//
// localStorage throws on access in some browser configurations (private
// browsing, site data blocked). An unguarded read inside a Stimulus connect()
// aborts the whole controller, so every call here is wrapped: reads fall back
// to null and writes become no-ops rather than taking the UI down with them.

export const storage = {
  get(key) {
    try {
      return localStorage.getItem(key)
    } catch {
      return null
    }
  },

  set(key, value) {
    try {
      localStorage.setItem(key, value)
      return true
    } catch {
      return false
    }
  },

  remove(key) {
    try {
      localStorage.removeItem(key)
      return true
    } catch {
      return false
    }
  },

  getBoolean(key) {
    return this.get(key) === "true"
  }
}
