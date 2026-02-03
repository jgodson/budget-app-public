import { Controller } from "@hotwired/stimulus"
import "chart.js"

// Connects to data-controller="investment-calculator"
export default class extends Controller {
  static targets = [
    "goalSelect",
    "goalAmount",
    "startingBalance",
    "contributionAmount",
    "annualReturn",
    "contributionFrequency",
    "warning",
    "goalStatusLabel",
    "goalStatusValue",
    "targetGoal",
    "totalContributed",
    "investmentGrowth",
    "finalBalance",
    "chartEmpty",
    "chart",
    "yearlyTableBody"
  ]

  static values = {
    maxYears: Number
  }

  connect() {
    if (document.documentElement.hasAttribute("data-turbo-preview")) return

    this.currencyFormatter = new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" })
    this.inputNumberFormatter = new Intl.NumberFormat("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })

    this.formatInitialInputs()
    this.applyGoalDefaults(false)
    this.recalculate()

    this.themeChangeListener = () => this.updateChartTheme()
    window.addEventListener("theme-changed", this.themeChangeListener)
  }

  formatInitialInputs() {
    if (this.goalAmountTarget?.value) {
      this.goalAmountTarget.value = this.formatInputNumber(this.goalAmountTarget.value)
    }
    if (this.startingBalanceTarget?.value) {
      this.startingBalanceTarget.value = this.formatInputNumber(this.startingBalanceTarget.value)
    }
    if (this.contributionAmountTarget?.value) {
      this.contributionAmountTarget.value = this.formatInputNumber(this.contributionAmountTarget.value)
    }
    if (this.annualReturnTarget?.value) {
      this.annualReturnTarget.value = this.formatInputNumber(this.annualReturnTarget.value)
    }
  }

  disconnect() {
    if (this.chartInstance) {
      this.chartInstance.destroy()
    }
    window.removeEventListener("theme-changed", this.themeChangeListener)
  }

  applyGoal() {
    this.applyGoalDefaults(true)
    this.recalculate()
  }

  updateFrequency() {
    const previousFrequency = this.contributionFrequencyTarget.dataset.previousFrequency || "monthly"
    const previousFactor = this.frequencyToMonthlyFactor(previousFrequency)
    const nextFactor = this.frequencyToMonthlyFactor(this.contributionFrequencyTarget.value)
    const currentAmount = this.parseNumber(this.contributionAmountTarget.value)
    const monthlyEquivalent = currentAmount * previousFactor
    const nextAmount = monthlyEquivalent / nextFactor

    this.contributionAmountTarget.value = nextAmount.toFixed(2)
    this.contributionFrequencyTarget.dataset.previousFrequency = this.contributionFrequencyTarget.value
    this.recalculate()
  }

  recalculate() {
    this.clearWarning()

    const goalAmount = this.parseNumber(this.goalAmountTarget.value)
    const startingBalance = this.parseNumber(this.startingBalanceTarget.value)
    const contributionAmount = this.parseNumber(this.contributionAmountTarget.value)
    const annualReturn = this.parseNumber(this.annualReturnTarget.value)
    const frequencyFactor = this.frequencyToMonthlyFactor(this.contributionFrequencyTarget.value)
    const monthlyContribution = contributionAmount * frequencyFactor

    if (goalAmount < 0 || startingBalance < 0 || contributionAmount < 0) {
      this.showWarning("Inputs must be zero or greater.")
      this.resetOutputs()
      return
    }

    if (goalAmount <= 0) {
      this.resetOutputs()
      return
    }

    if (startingBalance >= goalAmount) {
      const schedule = [{ date: new Date(), balance: startingBalance }]
      this.updateOutputs({
        goalReached: true,
        monthsToGoal: 0,
        projectedDate: new Date(),
        goalAmount,
        totalContributed: startingBalance,
        growth: 0,
        endingBalance: startingBalance
      })
      this.renderChart(schedule, goalAmount)
      this.renderYearlyTable(schedule)
      return
    }

    const monthlyRate = annualReturn / 100 / 12
    if (monthlyContribution <= 0 && monthlyRate <= 0) {
      this.showWarning("With no contributions and a non-positive return rate, the goal will not be reached.")
      this.resetOutputs()
      return
    }

    const maxMonths = (this.maxYearsValue || 100) * 12
    let balance = startingBalance
    let totalContributed = startingBalance
    let months = 0
    const schedule = []
    const startDate = new Date()

    while (months < maxMonths) {
      balance = (balance * (1 + monthlyRate)) + monthlyContribution
      totalContributed += monthlyContribution
      months += 1
      const date = this.addMonths(startDate, months)
      schedule.push({ date, balance })
      if (balance >= goalAmount) break
    }

    const goalReached = balance >= goalAmount
    const projectedDate = goalReached ? this.addMonths(startDate, months) : null
    const growth = balance - totalContributed

    this.updateOutputs({
      goalReached,
      monthsToGoal: goalReached ? months : null,
      projectedDate,
      goalAmount,
      totalContributed,
      growth,
      endingBalance: balance
    })
    this.renderChart(schedule, goalAmount)
    this.renderYearlyTable(schedule)
  }

  applyGoalDefaults(force) {
    const selectedOption = this.goalSelectTarget.options[this.goalSelectTarget.selectedIndex]
    const goalAmount = selectedOption?.dataset?.goalAmount
    const goalContributed = selectedOption?.dataset?.goalContributed
    const goalMonthly = selectedOption?.dataset?.goalMonthly
    const frequencyFactor = this.frequencyToMonthlyFactor(this.contributionFrequencyTarget.value)

    if (this.shouldAutofill(this.goalAmountTarget, force) && goalAmount !== undefined && goalAmount !== "") {
      this.goalAmountTarget.value = this.formatInputNumber(goalAmount)
    }

    if (this.shouldAutofill(this.startingBalanceTarget, force) && goalContributed !== undefined && goalContributed !== "") {
      this.startingBalanceTarget.value = this.formatInputNumber(goalContributed)
    }

    if (this.shouldAutofill(this.contributionAmountTarget, force) && goalMonthly !== undefined && goalMonthly !== "") {
      const contributionAmount = parseFloat(goalMonthly) / frequencyFactor
      this.contributionAmountTarget.value = this.formatInputNumber(contributionAmount)
    }

    this.contributionFrequencyTarget.dataset.previousFrequency = this.contributionFrequencyTarget.value
  }

  updateOutputs({ goalReached, monthsToGoal, projectedDate, goalAmount, totalContributed, growth, endingBalance }) {
    this.goalStatusLabelTarget.textContent = goalReached ? "Goal Reached (Estimated)" : "Goal Not Reached Yet"
    if (goalReached && projectedDate) {
      const dateLabel = projectedDate.toLocaleDateString("en-US", { month: "long", year: "numeric" })
      const durationLabel = this.formatDuration(monthsToGoal)
      this.goalStatusValueTarget.textContent = `${dateLabel} (${durationLabel})`
      this.setValueClass(this.goalStatusValueTarget, "text-success")
    } else {
      this.goalStatusValueTarget.textContent = `Not reached in ${this.maxYearsValue || 100} years`
      this.setValueClass(this.goalStatusValueTarget, "text-danger")
    }

    this.targetGoalTarget.textContent = this.currencyFormatter.format(goalAmount)
    this.totalContributedTarget.textContent = this.currencyFormatter.format(totalContributed)
    this.investmentGrowthTarget.textContent = this.currencyFormatter.format(growth)
    this.finalBalanceTarget.textContent = this.currencyFormatter.format(endingBalance)

    this.setValueClass(this.targetGoalTarget, null)
    this.setValueClass(this.totalContributedTarget, "text-warning")
    this.setValueClass(this.investmentGrowthTarget, "text-primary")
    this.setValueClass(this.finalBalanceTarget, "text-success")
  }

  resetOutputs() {
    this.goalStatusLabelTarget.textContent = "Goal Status"
    this.goalStatusValueTarget.textContent = "—"
    this.setValueClass(this.goalStatusValueTarget, "text-muted")
    this.targetGoalTarget.textContent = "—"
    this.totalContributedTarget.textContent = "—"
    this.investmentGrowthTarget.textContent = "—"
    this.finalBalanceTarget.textContent = "—"
    this.setValueClass(this.targetGoalTarget, "text-muted")
    this.setValueClass(this.totalContributedTarget, "text-muted")
    this.setValueClass(this.investmentGrowthTarget, "text-muted")
    this.setValueClass(this.finalBalanceTarget, "text-muted")
    this.renderChart([], 0)
    this.renderYearlyTable([])
  }

  renderYearlyTable(schedule) {
    if (!schedule.length) {
      this.yearlyTableBodyTarget.innerHTML = "<tr><td colspan=\"2\" class=\"text-center text-muted\">Projection details will appear here.</td></tr>"
      return
    }

    const yearly = {}
    schedule.forEach((row, index) => {
      const year = row.date.getFullYear()
      if (row.date.getMonth() === 11 || index === schedule.length - 1) {
        yearly[year] = row.balance
      }
    })

    const rows = Object.keys(yearly).sort((a, b) => Number(a) - Number(b)).map((year) => {
      return `
        <tr>
          <td>${year}</td>
          <td>${this.currencyFormatter.format(yearly[year])}</td>
        </tr>
      `
    }).join("")

    this.yearlyTableBodyTarget.innerHTML = rows
  }

  renderChart(schedule, goalAmount) {
    this.lastGoalAmount = goalAmount
    this.lastBalances = schedule.map((row) => row.balance)

    if (!schedule.length) {
      this.chartEmptyTarget.classList.remove("d-none")
      this.chartTarget.classList.add("d-none")
      if (this.chartInstance) {
        this.chartInstance.data.labels = []
        this.chartInstance.data.datasets.forEach((dataset) => { dataset.data = [] })
        this.chartInstance.update()
      }
      return
    }

    this.chartEmptyTarget.classList.add("d-none")
    this.chartTarget.classList.remove("d-none")

    const labels = []
    const balances = []
    const totalMonths = schedule.length
    const sampleEvery = totalMonths <= 120 ? 1 : (totalMonths <= 360 ? 3 : 12)

    schedule.forEach((row, index) => {
      if (index % sampleEvery === 0 || index === schedule.length - 1) {
        const labelFormat = sampleEvery >= 12 ? { year: "numeric" } : { month: "short", year: "numeric" }
        labels.push(row.date.toLocaleDateString("en-US", labelFormat))
        balances.push(Number(row.balance.toFixed(2)))
      }
    })

    const datasets = [
      {
        label: "Projected Balance",
        data: balances,
        borderColor: "#198754",
        backgroundColor: "rgba(25, 135, 84, 0.1)",
        fill: true,
        tension: 0.35
      },
      {
        label: "Goal",
        data: new Array(balances.length).fill(goalAmount),
        borderColor: "#dc3545",
        borderDash: [6, 6],
        pointRadius: 0
      }
    ]

    if (!this.chartInstance) {
      const ctx = this.chartTarget.getContext("2d")
      this.chartInstance = new window.Chart(ctx, {
        type: "line",
        data: { labels, datasets },
        options: this.chartOptions(goalAmount, balances)
      })
    } else {
      this.chartInstance.data.labels = labels
      this.chartInstance.data.datasets = datasets
      this.chartInstance.options = this.chartOptions(goalAmount, balances)
      this.chartInstance.update()
    }
  }

  chartOptions(goalAmount, balances) {
    const theme = document.documentElement.getAttribute("data-bs-theme")
    const textColor = theme === "dark" ? "#adb5bd" : "#666666"
    const gridColor = theme === "dark" ? "rgba(255, 255, 255, 0.1)" : "rgba(0, 0, 0, 0.1)"
    const chartMax = Math.max(goalAmount, Math.max(...balances, 0)) * 1.1

    return {
      responsive: true,
      maintainAspectRatio: false,
      interaction: { mode: "index", intersect: false },
      plugins: {
        legend: { display: true, position: "bottom", labels: { color: textColor } },
        tooltip: {
          callbacks: {
            label: (context) => {
              let label = context.dataset.label || ""
              if (label) { label += ": " }
              label += this.currencyFormatter.format(context.raw || 0)
              return label
            }
          }
        }
      },
      scales: {
        x: { ticks: { color: textColor }, grid: { color: gridColor } },
        y: { beginAtZero: true, suggestedMax: chartMax, ticks: { color: textColor }, grid: { color: gridColor } }
      }
    }
  }

  updateChartTheme() {
    if (!this.chartInstance) return
    this.chartInstance.options = this.chartOptions(this.lastGoalAmount || 0, this.lastBalances || [])
    this.chartInstance.update()
  }

  formatDuration(months) {
    const totalMonths = Number.isFinite(months) ? Math.max(0, Math.round(months)) : 0
    const years = Math.floor(totalMonths / 12)
    const remainingMonths = totalMonths % 12
    const yearLabel = years === 1 ? "year" : "years"
    const monthLabel = remainingMonths === 1 ? "month" : "months"
    if (years > 0 && remainingMonths > 0) {
      return `${years} ${yearLabel} ${remainingMonths} ${monthLabel}`
    }
    if (years > 0) {
      return `${years} ${yearLabel}`
    }
    return `${remainingMonths} ${monthLabel}`
  }

  shouldAutofill(element, force) {
    return force || element.dataset.autofill === "true"
  }

  setValueClass(element, className) {
    element.classList.remove("text-success", "text-danger", "text-muted", "text-warning", "text-primary")
    if (className) {
      element.classList.add(className)
    }
  }

  frequencyToMonthlyFactor(frequency) {
    switch (frequency) {
      case "biweekly":
        return 26 / 12
      case "weekly":
        return 52 / 12
      case "quarterly":
        return 1 / 3
      default:
        return 1
    }
  }

  parseNumber(value) {
    const normalized = value?.toString().replace(/,/g, "")
    const parsed = parseFloat(normalized)
    return Number.isFinite(parsed) ? parsed : 0
  }

  formatInputNumber(value) {
    const parsed = Number.isFinite(value) ? value : this.parseNumber(value)
    return this.inputNumberFormatter.format(parsed || 0)
  }

  addMonths(date, months) {
    const base = new Date(date.getTime())
    const day = base.getDate()
    base.setMonth(base.getMonth() + months)
    if (base.getDate() < day) {
      base.setDate(0)
    }
    return base
  }

  showWarning(message) {
    this.warningTarget.textContent = message
    this.warningTarget.classList.remove("d-none")
  }

  clearWarning() {
    this.warningTarget.textContent = ""
    this.warningTarget.classList.add("d-none")
  }
}
