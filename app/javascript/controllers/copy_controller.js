import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]

  copy() {
    const text = this.sourceTarget.value

    // Try modern clipboard API first
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text)
        .then(() => {
          this.showSuccess()
        })
        .catch(() => {
          this.fallbackCopy(text)
        })
    } else {
      this.fallbackCopy(text)
    }
  }

  fallbackCopy(text) {
    // Create a temporary textarea for copying
    const textarea = document.createElement('textarea')
    textarea.value = text
    textarea.style.position = 'fixed'
    textarea.style.opacity = '0'
    document.body.appendChild(textarea)

    try {
      textarea.select()
      textarea.setSelectionRange(0, 99999)
      const successful = document.execCommand('copy')

      if (successful) {
        this.showSuccess()
      } else {
        this.showError()
      }
    } catch (err) {
      this.showError()
    } finally {
      document.body.removeChild(textarea)
    }
  }

  showSuccess() {
    const originalHTML = this.buttonTarget.innerHTML

    // Change button to success state
    this.buttonTarget.innerHTML = `
      <svg class="h-4 w-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
      </svg>
      Copied!
    `
    this.buttonTarget.classList.remove('bg-blue-600', 'hover:bg-blue-700')
    this.buttonTarget.classList.add('bg-green-600', 'hover:bg-green-700')

    // Reset after 2 seconds
    setTimeout(() => {
      this.buttonTarget.innerHTML = originalHTML
      this.buttonTarget.classList.remove('bg-green-600', 'hover:bg-green-700')
      this.buttonTarget.classList.add('bg-blue-600', 'hover:bg-blue-700')
    }, 2000)
  }

  showError() {
    alert('Unable to copy automatically. Please select the text and copy manually.')
  }
}