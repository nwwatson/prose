// Shared fetch helpers: CSRF token header, JSON/FormData/URLSearchParams bodies,
// and the JSON / Turbo Stream response idioms repeated across Stimulus controllers.

export function csrfToken() {
  return document.querySelector("meta[name='csrf-token']")?.content
}

export function request(url, { method = "GET", body, headers = {}, accept } = {}) {
  const finalHeaders = { ...headers, "X-CSRF-Token": csrfToken() }
  if (accept) finalHeaders["Accept"] = accept

  if (body && typeof body === "object" && !(body instanceof FormData) && !(body instanceof URLSearchParams)) {
    finalHeaders["Content-Type"] = "application/json"
    body = JSON.stringify(body)
  } else if (body instanceof URLSearchParams) {
    finalHeaders["Content-Type"] = "application/x-www-form-urlencoded"
  }

  return fetch(url, { method, headers: finalHeaders, body })
}

export async function requestJSON(url, options = {}) {
  const response = await request(url, { accept: "application/json", ...options })
  const data = await response.json()

  if (!response.ok) {
    throw new Error(data.error || "Request failed")
  }

  return data
}

export async function requestTurboStream(url, options = {}) {
  const response = await request(url, { accept: "text/vnd.turbo-stream.html", ...options })
  const html = await response.text()
  window.Turbo.renderStreamMessage(html)
  return response
}
