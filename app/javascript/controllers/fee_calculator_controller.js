import { Controller } from "@hotwired/stimulus"

/**
 * Fee Calculator Controller
 *
 * Dynamically calculates and displays platform fees as user enters charge amount
 * Used on the new platform charge form
 */
export default class extends Controller {
  static targets = [
    "amount",           // The amount input field
    "feePercentage",    // Hidden field with fee percentage
    "chargeDisplay",    // Display for charge amount
    "feeDisplay",       // Display for fee amount
    "netDisplay"        // Display for net amount
  ]

  /**
   * Calculate fee breakdown and update all displays
   */
  calculate() {
    const amountCents = parseInt(this.amountTarget.value) || 0
    const feePercentage = parseFloat(this.feePercentageTarget.value) || 0

    // Calculate fee in cents
    const feeCents = Math.round(amountCents * (feePercentage / 100.0))
    const netCents = amountCents - feeCents

    // Convert to dollars for display
    const amountDollars = (amountCents / 100.0).toFixed(2)
    const feeDollars = (feeCents / 100.0).toFixed(2)
    const netDollars = (netCents / 100.0).toFixed(2)

    // Update all displays
    this.chargeDisplayTarget.textContent = `$${amountDollars}`
    this.feeDisplayTarget.textContent = `$${feeDollars}`
    this.netDisplayTarget.textContent = `$${netDollars}`

    // Update net display color based on amount
    if (netCents > 0) {
      this.netDisplayTarget.classList.remove("text-gray-600")
      this.netDisplayTarget.classList.add("text-green-600")
    } else {
      this.netDisplayTarget.classList.remove("text-green-600")
      this.netDisplayTarget.classList.add("text-gray-600")
    }
  }

  /**
   * Initialize with default calculation
   */
  connect() {
    this.calculate()
  }
}
