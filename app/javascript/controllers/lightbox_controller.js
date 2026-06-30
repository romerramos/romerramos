import { Controller } from "@hotwired/stimulus"

// Full-screen photo lightbox with prev/next, keyboard and swipe support.
// Reads photo data from the gallery's `item` button targets.
export default class extends Controller {
  static targets = ["item"]

  connect() {
    this.currentIndex = 0
    this.buildOverlay()
    this.onKeydown = this.onKeydown.bind(this)
  }

  disconnect() {
    this.overlay?.remove()
    document.removeEventListener("keydown", this.onKeydown)
    document.body.classList.remove("overflow-hidden")
  }

  open(event) {
    const button = event.currentTarget
    this.currentIndex = parseInt(button.dataset.index, 10)
    this.render()
    this.overlay.classList.remove("hidden")
    this.overlay.classList.add("flex")
    document.body.classList.add("overflow-hidden")
    document.addEventListener("keydown", this.onKeydown)
  }

  close() {
    this.overlay.classList.add("hidden")
    this.overlay.classList.remove("flex")
    document.body.classList.remove("overflow-hidden")
    document.removeEventListener("keydown", this.onKeydown)
    this.imageEl.src = ""
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

  render() {
    const button = this.itemTargets[this.currentIndex]
    const { largeUrl, title, caption } = button.dataset

    this.imageEl.src = largeUrl
    this.imageEl.alt = title || ""

    if (title || caption) {
      this.captionEl.classList.remove("hidden")
      this.titleEl.textContent = title || ""
      this.titleEl.classList.toggle("hidden", !title)
      this.captionTextEl.textContent = caption || ""
      this.captionTextEl.classList.toggle("hidden", !caption)
    } else {
      this.captionEl.classList.add("hidden")
    }

    const single = this.itemTargets.length <= 1
    this.prevBtn.classList.toggle("hidden", single)
    this.nextBtn.classList.toggle("hidden", single)
  }

  onKeydown(event) {
    switch (event.key) {
      case "Escape":
        this.close()
        break
      case "ArrowRight":
        this.next()
        break
      case "ArrowLeft":
        this.prev()
        break
    }
  }

  // ---- swipe ----
  onTouchStart(event) {
    this.touchStartX = event.changedTouches[0].screenX
  }

  onTouchEnd(event) {
    const delta = event.changedTouches[0].screenX - this.touchStartX
    if (Math.abs(delta) < 50) return
    delta < 0 ? this.next() : this.prev()
  }

  buildOverlay() {
    const overlay = document.createElement("div")
    overlay.className =
      "hidden fixed inset-0 z-50 items-center justify-center bg-navy/95 backdrop-blur-sm"
    overlay.innerHTML = `
      <button type="button" data-lightbox-close class="absolute top-4 right-4 md:top-6 md:right-8 text-white/70 hover:text-brand text-3xl leading-none cursor-pointer" aria-label="Close">&times;</button>
      <button type="button" data-lightbox-prev class="absolute left-3 md:left-8 top-1/2 -translate-y-1/2 text-white/70 hover:text-brand text-5xl leading-none cursor-pointer select-none" aria-label="Previous">&lsaquo;</button>
      <button type="button" data-lightbox-next class="absolute right-3 md:right-8 top-1/2 -translate-y-1/2 text-white/70 hover:text-brand text-5xl leading-none cursor-pointer select-none" aria-label="Next">&rsaquo;</button>
      <figure class="flex flex-col items-center max-w-[92vw] max-h-[90vh]">
        <img data-lightbox-image class="max-w-[92vw] max-h-[78vh] object-contain rounded-lg" alt="">
        <figcaption data-lightbox-caption class="hidden mt-4 text-center max-w-2xl px-4">
          <span data-lightbox-title class="block font-semibold text-white"></span>
          <span data-lightbox-caption-text class="block text-white/60 font-light mt-1"></span>
        </figcaption>
      </figure>
    `
    document.body.appendChild(overlay)

    this.overlay = overlay
    this.imageEl = overlay.querySelector("[data-lightbox-image]")
    this.captionEl = overlay.querySelector("[data-lightbox-caption]")
    this.titleEl = overlay.querySelector("[data-lightbox-title]")
    this.captionTextEl = overlay.querySelector("[data-lightbox-caption-text]")
    this.prevBtn = overlay.querySelector("[data-lightbox-prev]")
    this.nextBtn = overlay.querySelector("[data-lightbox-next]")

    overlay.querySelector("[data-lightbox-close]").addEventListener("click", () => this.close())
    this.prevBtn.addEventListener("click", () => this.prev())
    this.nextBtn.addEventListener("click", () => this.next())
    // Click outside the figure closes the lightbox.
    overlay.addEventListener("click", (event) => {
      if (event.target === overlay) this.close()
    })
    overlay.addEventListener("touchstart", (event) => this.onTouchStart(event), { passive: true })
    overlay.addEventListener("touchend", (event) => this.onTouchEnd(event), { passive: true })
  }
}
