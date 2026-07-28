import { Controller } from "@hotwired/stimulus"

// Everything that affects where a character lands, so the mirror wraps its text
// on exactly the same boundaries as the textarea.
const MIRRORED_STYLES = [
  "fontFamily", "fontSize", "fontWeight", "fontStyle", "lineHeight",
  "letterSpacing", "wordSpacing", "textIndent", "textTransform", "tabSize",
  "whiteSpace", "wordBreak", "overflowWrap",
  "paddingTop", "paddingRight", "paddingBottom", "paddingLeft",
  "borderTopWidth", "borderRightWidth", "borderBottomWidth", "borderLeftWidth"
]

export default class extends Controller {
  static targets = [
    "field",
    "mirror",
    "bar",
    "preview",
    "locale",
    "selection",
    "selectionStart",
    "selectionEnd",
    "instruction",
    "instructionPanel",
    "instructionToggle"
  ]

  #field = null

  connect() {
    // selectionchange covers mouse, keyboard and double-click selection. Marksmith
    // already owns the textarea's data-action, so we listen here instead.
    document.addEventListener("selectionchange", this.trackSelection)
    document.addEventListener("turbo:submit-end", this.reset)
  }

  disconnect() {
    document.removeEventListener("selectionchange", this.trackSelection)
    document.removeEventListener("turbo:submit-end", this.reset)
  }

  // Keeps the textarea focused, and its selection painted, when a button is used.
  keepSelection(event) {
    event.preventDefault()
  }

  // Regenerating a whole language is a selection rewrite spanning the entire field.
  regenerateAll(event) {
    const panel = event.currentTarget.closest("[data-locale]")
    const field = this.fieldTargets.find((element) => panel.contains(element))

    if (!field?.value) {
      event.preventDefault()
      return
    }

    this.localeTarget.value = panel.dataset.locale
    this.selectionTarget.value = field.value
    this.selectionStartTarget.value = 0
    this.selectionEndTarget.value = field.value.length
    // This path has no instruction of its own; drop anything left in the bar.
    this.instructionTarget.value = ""
    this.#hide()
  }

  toggleInstruction() {
    const opening = this.instructionPanelTarget.hidden
    this.instructionPanelTarget.hidden = !opening
    this.instructionToggleTarget.setAttribute("aria-expanded", String(opening))

    if (opening) {
      // Typing steals focus from the textarea, so hand the highlight to the mirror.
      this.#paintHighlight()
      this.instructionTarget.focus()
    } else {
      this.#clearHighlight()
      this.#field?.focus({ preventScroll: true })
    }
  }

  trackSelection = () => {
    // A new post has no bar to show: it has no id to rewrite against yet.
    if (!this.hasBarTarget) return

    const field = this.fieldTargets.find((element) => element === document.activeElement)
    if (!field) return

    // The textarea is painting its own selection again.
    this.#clearHighlight()

    const { selectionStart, selectionEnd, value } = field
    if (selectionStart === selectionEnd) {
      this.#hide()
      return
    }

    const selection = value.slice(selectionStart, selectionEnd)
    this.#field = field
    this.localeTarget.value = field.closest("[data-locale]").dataset.locale
    this.selectionTarget.value = selection
    this.selectionStartTarget.value = selectionStart
    this.selectionEndTarget.value = selectionEnd
    this.previewTarget.textContent = selection
    this.barTarget.hidden = false
  }

  // The swapped-in editor makes the stored offsets meaningless.
  reset = () => {
    if (!this.hasBarTarget) return
    this.instructionTarget.value = ""
    this.#field = null
    this.#hide()
  }

  #hide() {
    this.#clearHighlight()
    this.barTarget.hidden = true
    this.instructionPanelTarget.hidden = true
    this.instructionToggleTarget.setAttribute("aria-expanded", "false")
  }

  #paintHighlight() {
    const field = this.#field
    if (!field) return

    const panel = field.closest("[data-locale]")
    const mirror = this.mirrorTargets.find((element) => panel.contains(element))
    if (!mirror) return

    const [before, mark, after] = mirror.children
    const start = Number(this.selectionStartTarget.value)
    const end = Number(this.selectionEndTarget.value)
    before.textContent = field.value.slice(0, start)
    mark.textContent = field.value.slice(start, end)
    after.textContent = field.value.slice(end)

    const source = getComputedStyle(field)
    MIRRORED_STYLES.forEach((property) => { mirror.style[property] = source[property] })
    mirror.style.top = `${field.offsetTop}px`
    mirror.style.left = `${field.offsetLeft}px`
    mirror.style.width = `${field.offsetWidth}px`
    mirror.style.height = `${field.offsetHeight}px`

    mirror.hidden = false
    mirror.scrollTop = field.scrollTop

    // Let the mirror show through, and keep the real text painted on top of it.
    field.style.backgroundColor = "transparent"
    field.style.position = "relative"
    field.style.zIndex = "1"
  }

  #clearHighlight() {
    // Runs on every caret move, so do nothing unless a mirror is actually up.
    if (!this.mirrorTargets.some((mirror) => !mirror.hidden)) return

    this.mirrorTargets.forEach((mirror) => { mirror.hidden = true })
    this.fieldTargets.forEach((field) => {
      field.style.backgroundColor = ""
      field.style.position = ""
      field.style.zIndex = ""
    })
  }
}
