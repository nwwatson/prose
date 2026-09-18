// Reader's reading list — the single source of truth for every bookmark
// button on the page.
//
// Anonymous readers keep saved post ids in localStorage. Signed-in readers'
// ids come from <meta name="reading-list"> (see ReadingListHelper) and are
// written through the JSON endpoints; the first page they load signed in
// merges any ids saved on this device into their account.
//
// Account state is kept in module memory rather than re-read from the meta on
// every connect: a Turbo restoration visit (Back button) restores the head
// from its snapshot, which can predate the reader's last toggle. The meta is
// only trusted again when its `key` changes, i.e. on sign-in or sign-out.

import { storage } from "lib/storage"
import { requestJSON } from "lib/request"

const STORAGE_KEY = "reading_list"
export const CHANGED_EVENT = "reading-list:changed"

let state = null

function readMeta() {
  const meta = document.querySelector("meta[name='reading-list']")
  if (meta?.content !== "account") return { key: "local", mode: "local" }

  return {
    key: meta.dataset.key,
    mode: "account",
    ids: parseIds(meta.dataset.postIds),
    itemsUrl: meta.dataset.itemsUrl,
    importUrl: meta.dataset.importUrl
  }
}

function parseIds(json) {
  try {
    const ids = JSON.parse(json || "[]")
    return Array.isArray(ids) ? ids.map(Number).filter((id) => Number.isInteger(id) && id > 0) : []
  } catch {
    return []
  }
}

// Newest first, matching the order the reading list page shows.
function readLocal() {
  return parseIds(storage.get(STORAGE_KEY))
}

function writeLocal(ids) {
  if (ids.length) storage.set(STORAGE_KEY, JSON.stringify(ids))
  else storage.remove(STORAGE_KEY)
}

function current() {
  const meta = readMeta()

  if (!state || state.key !== meta.key) {
    state = meta
    if (state.mode === "account") importLocal()
  }

  // Re-read every time so a change made in another tab shows up.
  if (state.mode === "local") state.ids = readLocal()
  return state
}

function setAccountIds(ids) {
  state.ids = ids
  // Keep the meta current so the Turbo snapshot taken on the next navigation matches.
  const meta = document.querySelector("meta[name='reading-list']")
  if (meta) meta.dataset.postIds = JSON.stringify(ids)
}

function notify() {
  window.dispatchEvent(new CustomEvent(CHANGED_EVENT, { detail: { ids: [ ...state.ids ] } }))
}

async function importLocal() {
  const local = readLocal()
  if (!local.length) return

  const target = state
  try {
    const data = await requestJSON(target.importUrl, { method: "POST", body: { post_ids: local } })
    writeLocal([])
    if (state !== target) return
    setAccountIds(data.post_ids)
    notify()
  } catch (error) {
    // Leave the local ids in place; the next signed-in page load retries.
    console.warn("Could not sync reading list", error)
  }
}

export const readingList = {
  get mode() {
    return current().mode
  },

  ids() {
    return [ ...current().ids ]
  },

  has(postId) {
    return current().ids.includes(postId)
  },

  async toggle(postId) {
    const list = current()
    const saved = list.ids.includes(postId)
    const next = saved ? list.ids.filter((id) => id !== postId) : [ postId, ...list.ids ]

    if (list.mode === "local") {
      writeLocal(next)
      list.ids = next
      notify()
      return
    }

    // Optimistic: flip every button now, reconcile with the server's list after.
    const previous = list.ids
    setAccountIds(next)
    notify()

    try {
      const data = saved
        ? await requestJSON(`${list.itemsUrl}/${postId}`, { method: "DELETE" })
        : await requestJSON(list.itemsUrl, { method: "POST", body: { post_id: postId } })
      if (state === list) setAccountIds(data.post_ids)
    } catch (error) {
      console.warn("Could not update reading list", error)
      if (state === list) setAccountIds(previous)
    }

    if (state === list) notify()
  }
}
