class ApplicationController < ActionController::Base
  before_action :set_year_context

  private

  def set_year_context
    @selected_year = params[:year]&.to_i || Date.current.year
    
    # Memoize available years to avoid multiple DB queries if called multiple times, 
    # though this runs once per request.
    # We use a broad query to cover most bases.
    @available_years = Transaction.distinct.pluck(:date).map { |date| date.year }
    @available_years += Budget.select(:year).distinct.pluck(:year)
    @available_years << Date.current.year
    @available_years = @available_years.uniq.sort.reverse
  end

  def default_url_options
    return {} unless @selected_year

    { year: @selected_year }
  end
end
