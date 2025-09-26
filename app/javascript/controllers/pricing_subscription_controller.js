import { Controller } from "@hotwired/stimulus"

/**
 * Handles subscription form submission with proper billing cycle
 */
export default class extends Controller {
  static targets = ["billingCycle"]
  static values = { plan: String }

  connect() {
    // Listen for pricing toggle changes to update billing cycle
    document.addEventListener('pricing-toggle:changed', (event) => {
      this.updateBillingCycle(event.detail.period)
    })
  }

  disconnect() {
    document.removeEventListener('pricing-toggle:changed', this.updateBillingCycle)
  }

  updateBillingCycle(period) {
    // Update the hidden field based on the pricing toggle
    const billingCycle = period === 'annual' ? 'year' : 'month'
    this.billingCycleTarget.value = billingCycle
  }
}