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

  open() {
    // Show the container
    this.containerTarget.classList.remove("hidden")

    // Add outside click listener after a brief delay to avoid immediate close
    setTimeout(() => {
      document.addEventListener("click", this.boundClose)
    }, 100)
  }

  close(event) {
    // If event exists and click is inside container (not backdrop), don't close
    if (event && this.containerTarget.contains(event.target)) {
      const isBackdrop = event.target === this.containerTarget ||
                        event.target.closest('[data-mobile-sidebar-backdrop]')
      if (!isBackdrop) return
    }

    // Hide the container
    this.containerTarget.classList.add("hidden")

    // Remove outside click listener
    document.removeEventListener("click", this.boundClose)
  }
}
