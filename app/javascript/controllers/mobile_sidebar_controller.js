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
    // If called from document click listener, check if we should actually close
    if (event && event.currentTarget === document) {
      // Don't close if clicking inside the white sidebar content
      const sidebarContent = this.containerTarget.querySelector('.bg-white')
      if (sidebarContent && sidebarContent.contains(event.target)) {
        return
      }
    }

    // Close and cleanup
    this.containerTarget.classList.add("hidden")
    document.removeEventListener("click", this.boundClose)
  }
}
