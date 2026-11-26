// Copies text to the clipboard, resolving to whether it worked.
//
// navigator.clipboard is only exposed in secure contexts (HTTPS/localhost) and
// can reject when permission is denied, so fall back to execCommand.
export async function copyText(text) {
  if (navigator.clipboard?.writeText) {
    try {
      await navigator.clipboard.writeText(text)
      return true
    } catch {
      // fall through to the legacy path
    }
  }

  return legacyCopy(text)
}

function legacyCopy(text) {
  const textarea = document.createElement("textarea")
  textarea.value = text
  textarea.setAttribute("readonly", "")
  textarea.style.position = "fixed"
  textarea.style.opacity = "0"
  document.body.appendChild(textarea)
  textarea.select()

  try {
    return document.execCommand("copy")
  } catch {
    return false
  } finally {
    textarea.remove()
  }
}
