module ReportsHelper
  # Valori soglia in centesimi!
  def highlight_class(report_type, column, value)
    thresholds = {
      "daily" => {
        venduto_sport:    { yellow: ->(v) { v == 0 }, green: ->(v) { v > 1_000_000 } },
        saldo_gioco_sport:   { green: ->(v) { v > 500_000 }, red: ->(v) { v < -500_000 }, yellow: ->(v) { v == 0 } },
        venduto_virtual:     { yellow: ->(v) { v == 0 }, green: ->(v) { v > 1_000_000 } },
        saldo_gioco_virtual: { green: ->(v) { v > 500_000 }, red: ->(v) { v < -500_000 }, yellow: ->(v) { v == 0 } },
        saldo_cassa_totale:  { green: ->(v) { v > 500_000 }, red: ->(v) { v < -500_000 } }
      },
      "weekly" => {
        venduto_sport:    { yellow: ->(v) { v == 0 }, green: ->(v) { v > 5_000_000 } },
        saldo_gioco_sport:   { green: ->(v) { v > 1_500_000 }, red: ->(v) { v < -1_000_000 }, yellow: ->(v) { v == 0 } },
        venduto_virtual:     { yellow: ->(v) { v == 0 }, green: ->(v) { v > 4_000_000 } },
        saldo_gioco_virtual: { green: ->(v) { v > 1_500_000 }, red: ->(v) { v < -1_000_000 }, yellow: ->(v) { v == 0 } },
        saldo_cassa_totale:  { green: ->(v) { v > 1_000_000 }, red: ->(v) { v < -1_000_000 } }
      },
      "monthly" => {
        venduto_sport:    { yellow: ->(v) { v == 0 }, green: ->(v) { v > 15_000_000 } },
        saldo_gioco_sport:   { green: ->(v) { v > 2_000_000 }, red: ->(v) { v < -1_500_000 }, yellow: ->(v) { v == 0 } },
        venduto_virtual:     { yellow: ->(v) { v == 0 }, green: ->(v) { v > 12_000_000 } },
        saldo_gioco_virtual: { green: ->(v) { v > 2_000_000 }, red: ->(v) { v < -200_000 }, yellow: ->(v) { v == 0 } },
        saldo_cassa_totale:  { green: ->(v) { v > 2_000_000 }, red: ->(v) { v < -2_000_000 } }
      }
    }

    col = column.to_sym
    return "" unless thresholds.dig(report_type, col)
    rules = thresholds[report_type][col]

    return "bg-yellow-200 text-yellow-900 font-bold" if rules[:yellow]&.call(value)
    return "bg-green-200 text-green-900 font-bold" if rules[:green]&.call(value)
    return "bg-red-200 text-red-900 font-bold" if rules[:red]&.call(value)
    ""
  end
end