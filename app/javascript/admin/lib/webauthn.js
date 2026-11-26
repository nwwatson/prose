// WebAuthn encoding between the server's JSON (binary fields as base64url) and
// the ArrayBuffers the browser's credential APIs take and return.

export function base64urlToBuffer(base64url) {
  const base64 = base64url.replace(/-/g, "+").replace(/_/g, "/")
  const padded = base64.padEnd(base64.length + (4 - base64.length % 4) % 4, "=")
  const binary = atob(padded)
  const buffer = new ArrayBuffer(binary.length)
  const view = new Uint8Array(buffer)
  for (let i = 0; i < binary.length; i++) {
    view[i] = binary.charCodeAt(i)
  }
  return buffer
}

export function bufferToBase64url(buffer) {
  const bytes = new Uint8Array(buffer)
  let binary = ""
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i])
  }
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "")
}

// Turns registration or authentication options from the server into the
// `publicKey` argument of navigator.credentials.create()/get().
export function decodeOptions(options) {
  const decoded = { ...options, challenge: base64urlToBuffer(options.challenge) }

  if (options.user) {
    decoded.user = { ...options.user, id: base64urlToBuffer(options.user.id) }
  }

  for (const key of ["allowCredentials", "excludeCredentials"]) {
    if (options[key]) {
      decoded[key] = options[key].map(cred => ({ ...cred, id: base64urlToBuffer(cred.id) }))
    }
  }

  return decoded
}

// Turns a PublicKeyCredential from create() (attestation) or get() (assertion)
// into the JSON shape the server verifies.
export function serializeCredential(credential) {
  return {
    id: credential.id,
    rawId: bufferToBase64url(credential.rawId),
    type: credential.type,
    response: serializeResponse(credential.response),
    clientExtensionResults: credential.getClientExtensionResults()
  }
}

function serializeResponse(response) {
  if (response.attestationObject) {
    return {
      attestationObject: bufferToBase64url(response.attestationObject),
      clientDataJSON: bufferToBase64url(response.clientDataJSON)
    }
  }

  return {
    authenticatorData: bufferToBase64url(response.authenticatorData),
    clientDataJSON: bufferToBase64url(response.clientDataJSON),
    signature: bufferToBase64url(response.signature),
    userHandle: response.userHandle ? bufferToBase64url(response.userHandle) : null
  }
}
