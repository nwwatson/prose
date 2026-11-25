// Shared ActionText attachment insertion for Lexxy editor instances.

export function insertAttachment(editor, { sgid, html }) {
  const attachment = document.createElement("action-text-attachment")
  attachment.setAttribute("sgid", sgid)
  attachment.setAttribute("content-type", "text/html")
  attachment.setAttribute("content", JSON.stringify(html))
  editor.contents.insertHtml(attachment.outerHTML)
}
