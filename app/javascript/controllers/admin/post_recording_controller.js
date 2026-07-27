import { Controller } from "@hotwired/stimulus"

// Speech-only dictation. Pinning the bitrate keeps a full-length recording far
// below the server's size cap instead of relying on the browser default, which
// is tuned for music and varies per browser.
const AUDIO_BITS_PER_SECOND = 48_000

export default class extends Controller {
  static targets = [
    "input",
    "record",
    "stop",
    "submit",
    "timer",
    "preview",
    "unsupportedError",
    "permissionError",
    "sizeError",
    "emptyError"
  ]

  static values = {
    maxDuration: Number,
    maxSize: Number
  }

  connect() {
    if (!navigator.mediaDevices?.getUserMedia || !window.MediaRecorder) {
      this.recordTarget.disabled = true
      this.unsupportedErrorTarget.hidden = false
    }
  }

  disconnect() {
    this.releaseStream()
    this.stopTimer()
    this.revokePreview()
  }

  async start() {
    this.hideErrors()
    this.inputTarget.value = ""
    this.chunks = []
    this.revokePreview()
    this.previewTarget.hidden = true
    this.submitTarget.disabled = true

    try {
      this.stream = await navigator.mediaDevices.getUserMedia({ audio: true })

      const mimeType = this.preferredMimeType()
      const options = { audioBitsPerSecond: AUDIO_BITS_PER_SECOND }
      if (mimeType) options.mimeType = mimeType

      this.recorder = new MediaRecorder(this.stream, options)
      this.recorder.addEventListener("dataavailable", this.captureChunk)
      this.recorder.addEventListener("stop", this.finish)

      this.recorder.start()
      this.startedAt = Date.now()
      this.timerTarget.textContent = "00:00"
      this.startTimer()

      this.recordTarget.hidden = true
      this.stopTarget.hidden = false
      this.submitTarget.disabled = true
    } catch {
      this.releaseStream()
      this.permissionErrorTarget.hidden = false
    }
  }

  stop() {
    if (this.recorder?.state === "recording") this.recorder.stop()
  }

  captureChunk = ({ data }) => {
    if (data.size > 0) this.chunks.push(data)
  }

  finish = () => {
    this.stopTimer()
    this.releaseStream()

    const type = this.recorder.mimeType || this.chunks[0]?.type || "audio/webm"
    const blob = new Blob(this.chunks, { type })

    this.recordTarget.hidden = false
    this.stopTarget.hidden = true

    if (blob.size === 0) {
      this.emptyErrorTarget.hidden = false
      return
    }

    if (blob.size > this.maxSizeValue) {
      this.sizeErrorTarget.hidden = false
      return
    }

    const file = new File(
      [blob],
      `post-recording.${this.extensionFor(type)}`,
      { type }
    )
    const transfer = new DataTransfer()
    transfer.items.add(file)
    this.inputTarget.files = transfer.files

    this.revokePreview()
    this.previewUrl = URL.createObjectURL(blob)
    this.previewTarget.src = this.previewUrl
    this.previewTarget.hidden = false
    this.submitTarget.disabled = false
  }

  startTimer() {
    this.timerInterval = window.setInterval(() => {
      const elapsed = Math.floor((Date.now() - this.startedAt) / 1000)
      this.timerTarget.textContent = this.formatTime(elapsed)

      if (elapsed >= this.maxDurationValue) this.stop()
    }, 250)
  }

  stopTimer() {
    window.clearInterval(this.timerInterval)
  }

  releaseStream() {
    this.stream?.getTracks().forEach((track) => track.stop())
    this.stream = null
  }

  revokePreview() {
    if (this.previewUrl) URL.revokeObjectURL(this.previewUrl)
    this.previewUrl = null
  }

  preferredMimeType() {
    return [
      "audio/webm;codecs=opus",
      "audio/mp4;codecs=mp4a.40.2",
      "audio/mp4",
      "audio/ogg;codecs=opus"
    ].find((type) => MediaRecorder.isTypeSupported(type))
  }

  extensionFor(type) {
    if (type.includes("mp4")) return "m4a"
    if (type.includes("ogg")) return "ogg"
    return "webm"
  }

  formatTime(seconds) {
    const minutes = Math.floor(seconds / 60)
    const remainder = seconds % 60

    return `${String(minutes).padStart(2, "0")}:${String(remainder).padStart(2, "0")}`
  }

  hideErrors() {
    this.permissionErrorTarget.hidden = true
    this.sizeErrorTarget.hidden = true
    this.emptyErrorTarget.hidden = true
  }
}
