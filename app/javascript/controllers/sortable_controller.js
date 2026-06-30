import { Controller } from "@hotwired/stimulus"

// Drag-and-drop reordering using the native HTML5 Drag and Drop API.
// Persists the new order by PATCHing the ordered ids to `urlValue`.
export default class extends Controller {
  static targets = ["item"]
  static values = { url: String }

  connect() {
    this.dragEl = null
  }

  itemTargetConnected(item) {
    item.setAttribute("draggable", "true")
    item.addEventListener("dragstart", this.onDragStart)
    item.addEventListener("dragover", this.onDragOver)
    item.addEventListener("dragend", this.onDragEnd)
    item.addEventListener("drop", this.onDrop)
  }

  itemTargetDisconnected(item) {
    item.removeEventListener("dragstart", this.onDragStart)
    item.removeEventListener("dragover", this.onDragOver)
    item.removeEventListener("dragend", this.onDragEnd)
    item.removeEventListener("drop", this.onDrop)
  }

  onDragStart = (event) => {
    this.dragEl = event.currentTarget
    event.dataTransfer.effectAllowed = "move"
    this.dragEl.classList.add("opacity-40")
  }

  onDragOver = (event) => {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
    const target = event.currentTarget
    if (!this.dragEl || target === this.dragEl) return

    const rect = target.getBoundingClientRect()
    const after = (event.clientY - rect.top) / rect.height > 0.5
    if (after) {
      target.after(this.dragEl)
    } else {
      target.before(this.dragEl)
    }
  }

  onDrop = (event) => {
    event.preventDefault()
  }

  onDragEnd = () => {
    if (this.dragEl) this.dragEl.classList.remove("opacity-40")
    this.dragEl = null
    this.persist()
  }

  persist() {
    const ids = this.itemTargets.map((item) => item.dataset.id)
    const token = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": token,
        Accept: "application/json"
      },
      body: JSON.stringify({ ids })
    })
  }
}
