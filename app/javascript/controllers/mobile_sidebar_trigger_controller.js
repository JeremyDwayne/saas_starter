import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["openIcon", "closeIcon"]

  connect() {
    this.boundHandleClose = this.handleClose.bind(this)
    window.addEventListener("mobile-sidebar:closed", this.boundHandleClose)
  }

  disconnect() {
    window.removeEventListener("mobile-sidebar:closed", this.boundHandleClose)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    // Check if sidebar is open by checking if close icon is visible
    if (this.closeIconTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.openIconTarget.classList.add("hidden")
    this.closeIconTarget.classList.remove("hidden")
    window.dispatchEvent(new CustomEvent("mobile-sidebar:open"))
  }

  close() {
    this.openIconTarget.classList.remove("hidden")
    this.closeIconTarget.classList.add("hidden")
    window.dispatchEvent(new CustomEvent("mobile-sidebar:close"))
  }

  handleClose() {
    this.openIconTarget.classList.remove("hidden")
    this.closeIconTarget.classList.add("hidden")
  }
}
