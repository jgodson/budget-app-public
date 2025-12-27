module TransactionsHelper
  def status_class(status)
    case status
    when :new
      'text-bg-success'
    when :potential_duplicate
      'text-bg-danger'
    when :duplicate
      'text-bg-warning'
    when :ignored
      'text-bg-secondary'
    else
      'text-bg-secondary'
    end
  end

  def transaction_source_badge(transaction)
    source = transaction.import_source
    badge_class, icon_class = case source
                              when 'Manual'
                                ['bg-secondary', 'bi-pencil-fill']
                              when 'Goal Contribution'
                                ['bg-info text-dark', 'bi-bullseye']
                              when 'Loan Payment'
                                ['bg-primary', 'bi-bank']
                              else
                                # Assuming everything else is an import service
                                ['bg-light text-dark border', 'bi-cloud-upload']
                              end

    tag.span(class: "badge #{badge_class} d-inline-flex align-items-center gap-1", title: source, data: { bs_toggle: "tooltip" }) do
      concat tag.i(class: "bi #{icon_class}")
      concat span_text_for_source(source)
    end
  end

  private

  def span_text_for_source(source)
    source
  end
end
