import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["backdrop", "panel", "sidebar"]
  static values = { open: Boolean }

  connect() {
    this.openValue = false
  }

  open() {
    this.openValue = true
    this.update()
  }

  close() {
    this.openValue = false
    this.update()
  }

  toggle() {
    this.openValue = !this.openValue
    this.update()
  }

  update() {
    if (this.openValue) {
      // Show backdrop
      this.backdropTarget.classList.remove("hidden")

      // Show and animate sidebar
      requestAnimationFrame(() => {
        this.sidebarTarget.classList.remove("-translate-x-full")
        this.sidebarTarget.classList.add("translate-x-0")
      })

      // Prevent body scroll
      document.body.style.overflow = "hidden"
    } else {
      // Hide sidebar
      this.sidebarTarget.classList.remove("translate-x-0")
      this.sidebarTarget.classList.add("-translate-x-full")

      // Hide backdrop after animation
      setTimeout(() => {
        this.backdropTarget.classList.add("hidden")
      }, 300)

      // Restore body scroll
      document.body.style.overflow = ""
    }
  }

  // Close sidebar when clicking outside or on links
  backdropClicked() {
    this.close()
  }
}