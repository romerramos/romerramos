import { Controller } from "@hotwired/stimulus"

// Drag-and-drop reordering using the native HTML5 Drag and Drop API.
// On drop, the new order is written into a hidden Rails form which is
// submitted with requestSubmit() so Turbo handles the request (and CSRF).
export default class extends Controller {
  static targets = ["item", "form", "field"]

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
    after ? target.after(this.dragEl) : target.before(this.dragEl)
  }

  onDrop = (event) => {
    event.preventDefault()
  }

  onDragEnd = () => {
    if (this.dragEl) this.dragEl.classList.remove("opacity-40")
    this.dragEl = null
    this.submit()
  }

  submit() {
    this.fieldTarget.value = this.itemTargets.map((item) => item.dataset.id).join(",")
    this.formTarget.requestSubmit()
  }
}
