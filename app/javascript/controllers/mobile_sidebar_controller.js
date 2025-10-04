import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  connect() {
    // Listen for open event from navbar trigger
    this.boundOpen = this.open.bind(this)
    this.boundClose = this.close.bind(this)
    window.addEventListener("mobile-sidebar:open", this.boundOpen)
  }

  disconnect() {
    window.removeEventListener("mobile-sidebar:open", this.boundOpen)
    document.removeEventListener("click", this.boundClose)
  }

  open(event) {
    // Show the container
    this.containerTarget.classList.remove("hidden")

    // Add outside click listener on next tick to avoid immediate close
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        document.addEventListener("click", this.boundClose)
      })
    })
  }

  close(event) {
    // If called from close button, just close
    if (!event || event.type !== "click") {
      this.containerTarget.classList.add("hidden")
      document.removeEventListener("click", this.boundClose)
      return
    }

    // For document clicks, check if clicking backdrop or outside
    const clickedBackdrop = event.target.hasAttribute('data-mobile-sidebar-backdrop')
    const clickedOutside = !this.element.contains(event.target)

    if (clickedBackdrop || clickedOutside) {
      this.containerTarget.classList.add("hidden")
      document.removeEventListener("click", this.boundClose)
    }
  }
}
