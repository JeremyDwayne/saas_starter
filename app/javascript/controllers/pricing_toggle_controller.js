import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle", "priceAmount", "pricePeriod", "annualSavings"]

  connect() {
    this.updatePricing('monthly')
  }

  switch(event) {
    const period = event.target.dataset.period
    this.updatePricing(period)
  }

  updatePricing(period) {
    // Update active state
    this.toggleTargets.forEach(btn => btn.classList.remove('active'))
    const activeButton = this.toggleTargets.find(btn => btn.dataset.period === period)
    if (activeButton) {
      activeButton.classList.add('active')
    }

    // Update prices
    this.priceAmountTargets.forEach(amount => {
      const monthlyPrice = amount.dataset.monthly
      const annualPrice = amount.dataset.annual

      if (period === 'monthly') {
        amount.textContent = '$' + monthlyPrice
      } else {
        amount.textContent = '$' + annualPrice
      }
    })

    // Update period text
    this.pricePeriodTargets.forEach(periodEl => {
      if (period === 'monthly') {
        periodEl.textContent = '/month'
      } else {
        periodEl.textContent = '/year'
      }
    })

    // Show/hide annual savings
    this.annualSavingsTargets.forEach(savings => {
      if (period === 'annual') {
        savings.style.display = 'block'
      } else {
        savings.style.display = 'none'
      }
    })
  }
}