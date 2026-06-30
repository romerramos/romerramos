import { Controller } from "@hotwired/stimulus"

// Full-screen photo lightbox. All markup lives in the `art/_lightbox` partial;
// this controller only handles behavior: open/close, navigation, keys and swipe.
export default class extends Controller {
  static targets = [
    "item", "overlay", "image", "title", "caption", "captionText", "prev", "next"
  ]

  connect() {
    this.currentIndex = 0
    this.onKeydown = this.onKeydown.bind(this)
  }

  disconnect() {
    this.unlockScroll()
    document.removeEventListener("keydown", this.onKeydown)
  }

  open(event) {
    this.currentIndex = Number(event.currentTarget.dataset.index)
    this.render()
    this.overlayTarget.classList.replace("hidden", "flex")
    this.lockScroll()
    document.addEventListener("keydown", this.onKeydown)
  }

  close() {
    this.overlayTarget.classList.replace("flex", "hidden")
    this.unlockScroll()
    document.removeEventListener("keydown", this.onKeydown)
    this.imageTarget.removeAttribute("src")
  }

  next() {
    this.currentIndex = (this.currentIndex + 1) % this.itemTargets.length
    this.render()
  }

  prev() {
    const count = this.itemTargets.length
    this.currentIndex = (this.currentIndex - 1 + count) % count
    this.render()
  }

  // Close only when the backdrop itself (not the photo or controls) is clicked.
  backdropClose(event) {
    if (event.target === this.overlayTarget) this.close()
  }

  render() {
    const { largeUrl, title, caption } = this.itemTargets[this.currentIndex].dataset

    this.imageTarget.src = largeUrl
    this.imageTarget.alt = title || ""

    this.titleTarget.textContent = title || ""
    this.titleTarget.classList.toggle("hidden", !title)
    this.captionTextTarget.textContent = caption || ""
    this.captionTextTarget.classList.toggle("hidden", !caption)
    this.captionTarget.classList.toggle("hidden", !title && !caption)

    const single = this.itemTargets.length <= 1
    this.prevTarget.classList.toggle("hidden", single)
    this.nextTarget.classList.toggle("hidden", single)
  }

  onKeydown(event) {
    if (event.key === "Escape") this.close()
    else if (event.key === "ArrowRight") this.next()
    else if (event.key === "ArrowLeft") this.prev()
  }

  touchStart(event) {
    this.touchStartX = event.changedTouches[0].screenX
  }

  touchEnd(event) {
    const delta = event.changedTouches[0].screenX - this.touchStartX
    if (Math.abs(delta) < 50) return
    delta < 0 ? this.next() : this.prev()
  }

  lockScroll() {
    document.body.classList.add("overflow-hidden")
  }

  unlockScroll() {
    document.body.classList.remove("overflow-hidden")
  }
}
