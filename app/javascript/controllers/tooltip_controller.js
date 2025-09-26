import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tooltip"]
  static values = { text: String, position: String }

  connect() {
    this.tooltip = null
    this.showTimeout = null
    this.hideTimeout = null
  }

  disconnect() {
    this.hide()
    this.clearTimeouts()
  }

  mouseenter() {
    this.clearTimeouts()

    // Only show tooltip if sidebar is collapsed
    const sidebar = document.querySelector('[data-controller*="sidebar"]')
    const isCollapsed = sidebar?.getAttribute('data-sidebar-collapsed-value') === 'true'

    if (isCollapsed) {
      this.showTimeout = setTimeout(() => {
        this.show()
      }, 300) // Small delay before showing
    }
  }

  mouseleave() {
    this.clearTimeouts()
    this.hideTimeout = setTimeout(() => {
      this.hide()
    }, 100) // Small delay before hiding
  }

  show() {
    if (this.tooltip) return

    this.tooltip = document.createElement('div')
    this.tooltip.className = 'fixed z-50 px-2 py-1 text-sm font-medium text-white bg-gray-900 rounded shadow-lg pointer-events-none whitespace-nowrap'
    this.tooltip.textContent = this.textValue

    document.body.appendChild(this.tooltip)

    // Position the tooltip
    this.positionTooltip()
  }

  hide() {
    if (this.tooltip) {
      document.body.removeChild(this.tooltip)
      this.tooltip = null
    }
  }

  positionTooltip() {
    if (!this.tooltip) return

    const rect = this.element.getBoundingClientRect()
    const tooltipRect = this.tooltip.getBoundingClientRect()

    // Position to the right of the element
    let left = rect.right + 8
    let top = rect.top + (rect.height - tooltipRect.height) / 2

    // Ensure tooltip stays within viewport
    if (left + tooltipRect.width > window.innerWidth) {
      left = rect.left - tooltipRect.width - 8
    }

    if (top < 8) {
      top = 8
    } else if (top + tooltipRect.height > window.innerHeight - 8) {
      top = window.innerHeight - tooltipRect.height - 8
    }

    this.tooltip.style.left = `${left}px`
    this.tooltip.style.top = `${top}px`
  }

  clearTimeouts() {
    if (this.showTimeout) {
      clearTimeout(this.showTimeout)
      this.showTimeout = null
    }
    if (this.hideTimeout) {
      clearTimeout(this.hideTimeout)
      this.hideTimeout = null
    }
  }
}