import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["lineItems", "template", "subtotal", "tax", "total"]

  connect() {
    this.updateTotals()
  }

  addLineItem(event) {
    event.preventDefault()

    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.lineItemsTarget.insertAdjacentHTML("beforeend", content)
  }

  removeLineItem(event) {
    event.preventDefault()

    const lineItem = event.target.closest(".line-item")

    // If this is a persisted record, mark for destruction
    const destroyInput = lineItem.querySelector('input[name*="_destroy"]')
    if (destroyInput) {
      destroyInput.value = "1"
      lineItem.style.display = "none"
    } else {
      // Otherwise just remove it from the DOM
      lineItem.remove()
    }

    this.updateTotals()
  }

  productSelected(event) {
    const select = event.target
    const lineItem = select.closest(".line-item")
    const productId = select.value

    if (!productId) return

    // Find the selected product from data attributes
    const option = select.options[select.selectedIndex]
    const description = option.dataset.description
    const price = option.dataset.price
    const unitType = option.dataset.unitType

    // Update the line item fields
    const descriptionField = lineItem.querySelector('input[name*="[description]"]')
    const priceField = lineItem.querySelector('input[name*="[unit_price_dollars]"]')
    const quantityField = lineItem.querySelector('input[name*="[quantity]"]')

    if (descriptionField && description) {
      descriptionField.value = description
    }

    if (priceField && price) {
      priceField.value = price
    }

    if (quantityField && !quantityField.value) {
      quantityField.value = "1"
    }

    this.updateLineItemTotal(lineItem)
  }

  updateLineItemTotal(lineItem) {
    const quantityField = lineItem.querySelector('input[name*="[quantity]"]')
    const priceField = lineItem.querySelector('input[name*="[unit_price_dollars]"]')
    const totalDisplay = lineItem.querySelector(".line-item-total")

    const quantity = parseFloat(quantityField?.value) || 0
    const price = parseFloat(priceField?.value) || 0
    const total = quantity * price

    if (totalDisplay) {
      totalDisplay.textContent = "$" + total.toFixed(2)
    }

    this.updateTotals()
  }

  quantityChanged(event) {
    const lineItem = event.target.closest(".line-item")
    this.updateLineItemTotal(lineItem)
  }

  priceChanged(event) {
    const lineItem = event.target.closest(".line-item")
    this.updateLineItemTotal(lineItem)
  }

  updateTotals() {
    let subtotal = 0

    this.lineItemsTarget.querySelectorAll(".line-item").forEach(lineItem => {
      // Skip hidden (destroyed) line items
      if (lineItem.style.display === "none") return

      const quantityField = lineItem.querySelector('input[name*="[quantity]"]')
      const priceField = lineItem.querySelector('input[name*="[unit_price_dollars]"]')

      const quantity = parseFloat(quantityField?.value) || 0
      const price = parseFloat(priceField?.value) || 0

      subtotal += quantity * price
    })

    const tax = 0 // Tax calculation can be added later
    const total = subtotal + tax

    if (this.hasSubtotalTarget) {
      this.subtotalTarget.textContent = "$" + subtotal.toFixed(2)
    }

    if (this.hasTaxTarget) {
      this.taxTarget.textContent = "$" + tax.toFixed(2)
    }

    if (this.hasTotalTarget) {
      this.totalTarget.textContent = "$" + total.toFixed(2)
    }
  }
}
