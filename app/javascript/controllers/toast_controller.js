import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "progress", "progressBar"]
  static values = {
    type: String,
    autoDismiss: Boolean,
    duration: Number
  }

  connect() {
    this.show()

    if (this.autoDismissValue) {
      this.startAutoDismiss()
    }
  }

  show() {
    // Trigger reflow to ensure the element is rendered before animation
    this.containerTarget.offsetHeight

    // Show the toast with animation
    requestAnimationFrame(() => {
      this.containerTarget.classList.remove("opacity-0", "translate-x-full")
      this.containerTarget.classList.add("opacity-100", "translate-x-0")
    })
  }

  dismiss() {
    // Clear any running timers
    if (this.dismissTimer) {
      clearTimeout(this.dismissTimer)
    }
    if (this.progressTimer) {
      clearInterval(this.progressTimer)
    }

    // Animate out
    this.containerTarget.classList.remove("opacity-100", "translate-x-0")
    this.containerTarget.classList.add("opacity-0", "translate-x-full")

    // Remove from DOM after animation
    setTimeout(() => {
      if (this.element.parentNode) {
        this.element.remove()
      }
    }, 300)
  }

  startAutoDismiss() {
    const duration = this.durationValue || 5000
    let timeLeft = duration
    const updateInterval = 50 // Update every 50ms for smooth animation

    // Update progress bar
    this.progressTimer = setInterval(() => {
      timeLeft -= updateInterval
      const percentage = (timeLeft / duration) * 100

      if (this.hasProgressTarget) {
        this.progressTarget.style.width = `${Math.max(0, percentage)}%`
      }

      if (timeLeft <= 0) {
        clearInterval(this.progressTimer)
      }
    }, updateInterval)

    // Auto dismiss after duration
    this.dismissTimer = setTimeout(() => {
      this.dismiss()
    }, duration)
  }

  // Pause auto-dismiss on hover
  pauseAutoDismiss() {
    if (this.dismissTimer) {
      clearTimeout(this.dismissTimer)
    }
    if (this.progressTimer) {
      clearInterval(this.progressTimer)
    }
  }

  // Resume auto-dismiss when hover ends
  resumeAutoDismiss() {
    if (this.autoDismissValue && this.hasProgressTarget) {
      // Get remaining time from progress bar width
      const currentWidth = parseFloat(this.progressTarget.style.width) || 0
      const remainingTime = (currentWidth / 100) * this.durationValue

      if (remainingTime > 0) {
        this.startAutoDismissWithTime(remainingTime)
      }
    }
  }

  startAutoDismissWithTime(remainingTime) {
    let timeLeft = remainingTime
    const updateInterval = 50

    this.progressTimer = setInterval(() => {
      timeLeft -= updateInterval
      const percentage = (timeLeft / this.durationValue) * 100

      if (this.hasProgressTarget) {
        this.progressTarget.style.width = `${Math.max(0, percentage)}%`
      }

      if (timeLeft <= 0) {
        clearInterval(this.progressTimer)
      }
    }, updateInterval)

    this.dismissTimer = setTimeout(() => {
      this.dismiss()
    }, remainingTime)
  }

  disconnect() {
    if (this.dismissTimer) {
      clearTimeout(this.dismissTimer)
    }
    if (this.progressTimer) {
      clearInterval(this.progressTimer)
    }
  }
}