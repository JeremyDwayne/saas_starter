import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open(event) {
    event.preventDefault()
    event.stopPropagation()
    window.dispatchEvent(new CustomEvent("mobile-sidebar:open"))
  }
}
