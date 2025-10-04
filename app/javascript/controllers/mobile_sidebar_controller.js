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
    const sidebar = this.containerTarget.querySelector('[data-sidebar-panel]')

    // Show the container
    this.containerTarget.classList.remove("hidden")

    // Slide in the sidebar
    requestAnimationFrame(() => {
      sidebar.classList.remove("-translate-x-full")
      sidebar.classList.add("translate-x-0")
    })

    // Add outside click listener after animation starts
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

    const sidebar = this.containerTarget.querySelector('[data-sidebar-panel]')

    // Slide out the sidebar
    sidebar.classList.remove("translate-x-0")
    sidebar.classList.add("-translate-x-full")

    // Hide container after animation
    setTimeout(() => {
      this.containerTarget.classList.add("hidden")
    }, 300)

    // Remove click listener
    document.removeEventListener("click", this.boundClose)
  }
}
