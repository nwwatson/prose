// Show and hide elements that animate between an "off" and an "on" set of
// classes and are `hidden` (display: none) once fully off — dropdowns,
// backdrops and overlays.
//
// fadeOut only adds `hidden` after the transition ends, so an element shown
// again before then must not be hidden by that stale callback: every call
// here first cancels the element's pending hide.

const pendingHides = new WeakMap()

function cancelPendingHide(el) {
  pendingHides.get(el)?.()
}

function toSeconds(value) {
  const trimmed = value.trim()
  const number = parseFloat(trimmed) || 0
  return trimmed.endsWith("ms") ? number / 1000 : number
}

function longestTransitionMs(el) {
  const style = getComputedStyle(el)
  const durations = style.transitionDuration.split(",").map(toSeconds)
  const delays = style.transitionDelay.split(",").map(toSeconds)
  const totals = durations.map((duration, i) => duration + (delays[i % delays.length] || 0))
  return Math.max(0, ...totals) * 1000
}

export function fadeIn(el, { off = [ "opacity-0" ], on = [] } = {}) {
  cancelPendingHide(el)
  el.classList.remove("hidden")
  // Force a reflow so the class change below transitions from the off state.
  el.offsetHeight // eslint-disable-line no-unused-expressions
  el.classList.remove(...off)
  el.classList.add(...on)
}

// `waitFor` is the element whose transition decides when to hide `el`
// (defaults to `el` itself). A timer backs up `transitionend`, which never
// fires when the element is not rendered (e.g. `lg:hidden` on desktop).
export function fadeOut(el, { off = [ "opacity-0" ], on = [], waitFor = el } = {}) {
  cancelPendingHide(el)
  el.classList.remove(...on)
  el.classList.add(...off)

  const ms = longestTransitionMs(waitFor)
  if (ms === 0) {
    el.classList.add("hidden")
    return
  }

  const onTransitionEnd = (event) => {
    if (event.target === waitFor) finish()
  }
  const cleanup = () => {
    clearTimeout(timer)
    waitFor.removeEventListener("transitionend", onTransitionEnd)
    pendingHides.delete(el)
  }
  const finish = () => {
    cleanup()
    el.classList.add("hidden")
  }
  const timer = setTimeout(finish, ms + 50)

  waitFor.addEventListener("transitionend", onTransitionEnd)
  pendingHides.set(el, cleanup)
}

// Hide at once, without a transition.
export function hide(el, { off = [ "opacity-0" ], on = [] } = {}) {
  cancelPendingHide(el)
  el.classList.remove(...on)
  el.classList.add(...off, "hidden")
}
