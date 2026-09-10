// Small DOM/string helpers shared across Stimulus controllers and other lib
// modules. Kept dependency-free so anything can import it.

// Escapes a string for interpolation into an HTML template literal. Quotes are
// escaped too, so the result is also safe inside a double- or single-quoted
// attribute value.
export function escapeHtml(str) {
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;")
}

// Upper-cases the first character only, leaving the rest untouched — used to
// build Stimulus `has<Name>Target` property names from a target name.
export function capitalize(str) {
  if (!str) return ""
  return str.charAt(0).toUpperCase() + str.slice(1)
}
