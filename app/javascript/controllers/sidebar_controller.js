import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "trigger", "triggerIcon", "tooltip", "navText", "navItem", "userInfo"]
  static values = { collapsed: Boolean }

  connect() {
    // Load saved state from localStorage
    const savedState = localStorage.getItem("sidebarCollapsed")
    this.collapsedValue = savedState === "true"
    this.updateSidebar()
  }

  toggle() {
    this.collapsedValue = !this.collapsedValue
    this.updateSidebar()
    // Save state to localStorage
    localStorage.setItem("sidebarCollapsed", this.collapsedValue.toString())
  }

  updateSidebar() {
    if (this.collapsedValue) {
      this.collapse()
    } else {
      this.expand()
    }
  }

  collapse() {
    // Update sidebar width
    this.sidebarTarget.classList.remove("lg:w-64")
    this.sidebarTarget.classList.add("lg:w-16")

    // Hide text elements
    this.navTextTargets.forEach(text => {
      text.classList.add("lg:hidden")
    })

    // Hide user info text
    if (this.hasUserInfoTarget) {
      this.userInfoTarget.classList.add("lg:hidden")
    }

    // Update trigger position and tooltip
    this.updateTrigger(true)

    // Update main content margin
    this.updateMainContentMargin(true)
  }

  expand() {
    // Update sidebar width
    this.sidebarTarget.classList.remove("lg:w-16")
    this.sidebarTarget.classList.add("lg:w-64")

    // Show text elements
    this.navTextTargets.forEach(text => {
      text.classList.remove("lg:hidden")
    })

    // Hide any visible global tooltip
    this.hideGlobalTooltip()

    // Show user info text
    if (this.hasUserInfoTarget) {
      this.userInfoTarget.classList.remove("lg:hidden")
    }

    // Update trigger position and tooltip
    this.updateTrigger(false)

    // Update main content margin
    this.updateMainContentMargin(false)
  }

  updateTrigger(collapsed) {
    if (!this.hasTriggerTarget) return

    // Position is now relative to sidebar (calc(100% - 8px)), so no need to change left
    // The trigger will automatically move with the sidebar

    // Update tooltip text
    if (this.hasTooltipTarget) {
      this.tooltipTarget.textContent = collapsed ? "Expand" : "Collapse"
    }
  }

  triggerHover() {
    if (!this.hasTriggerIconTarget) return

    // Show arrow based on current state
    if (this.collapsedValue) {
      this.triggerIconTarget.textContent = "›"  // Expand arrow
    } else {
      this.triggerIconTarget.textContent = "‹"  // Collapse arrow
    }

    // Show tooltip
    if (this.hasTooltipTarget) {
      this.tooltipTarget.classList.remove("opacity-0")
      this.tooltipTarget.classList.add("opacity-100")
    }
  }

  triggerLeave() {
    if (!this.hasTriggerIconTarget) return

    // Return to default pipe character
    this.triggerIconTarget.textContent = "|"

    // Hide tooltip
    if (this.hasTooltipTarget) {
      this.tooltipTarget.classList.remove("opacity-100")
      this.tooltipTarget.classList.add("opacity-0")
    }
  }

  navItemHover(event) {
    // Only show tooltips when sidebar is collapsed
    if (!this.collapsedValue) return

    // Get the nav item name from data attribute
    const navName = event.currentTarget.dataset.navName
    if (!navName) return

    // Show global tooltip
    this.showGlobalTooltip(event.currentTarget, navName)
  }

  navItemLeave(event) {
    // Hide global tooltip
    this.hideGlobalTooltip()
  }

  showGlobalTooltip(element, text) {
    const tooltip = document.getElementById('sidebar-tooltip')
    if (!tooltip) return

    // Set tooltip text
    tooltip.textContent = text

    // Position tooltip relative to the element
    const rect = element.getBoundingClientRect()
    tooltip.style.left = `${rect.right + 8}px`
    tooltip.style.top = `${rect.top + (rect.height / 2)}px`
    tooltip.style.transform = 'translateY(-50%)'

    // Show tooltip
    tooltip.classList.remove('hidden', 'opacity-0')
    tooltip.classList.add('opacity-100')
  }

  hideGlobalTooltip() {
    const tooltip = document.getElementById('sidebar-tooltip')
    if (!tooltip) return

    tooltip.classList.remove('opacity-100')
    tooltip.classList.add('opacity-0')

    // Hide after transition
    setTimeout(() => {
      tooltip.classList.add('hidden')
    }, 200)
  }

  updateMainContentMargin(collapsed) {
    const mainContent = document.querySelector('main.lg\\:pl-64')
    if (mainContent) {
      if (collapsed) {
        mainContent.classList.remove("lg:pl-64")
        mainContent.classList.add("lg:pl-16")
      } else {
        mainContent.classList.remove("lg:pl-16")
        mainContent.classList.add("lg:pl-64")
      }
    }
  }
}