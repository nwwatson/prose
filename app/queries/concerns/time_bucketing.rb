module TimeBucketing
  def by_day(scope, column)
    expr = Arel::Nodes::NamedFunction.new("DATE", [ scope.arel_table[column] ])
    scope.group(expr).order(expr).count
  end

  def by_month(scope, column)
    expr = month_bucket(scope, column)
    scope.group(expr).order(expr).count
  end

  def month_bucket(scope, column)
    Arel::Nodes::NamedFunction.new("strftime", [ Arel.sql("'%Y-%m'"), scope.arel_table[column] ])
  end

  def trend_comparison(scope, column, period:)
    current_start, previous_start, previous_end = period_bounds(period)

    current_count = scope.where(column => current_start..).count
    previous_count = scope.where(column => previous_start..previous_end).count

    { current: current_count, previous: previous_count, change: percentage_change(current_count, previous_count) }
  end

  def percentage(numerator, denominator)
    return 0.0 if denominator.zero?

    (numerator.to_f / denominator * 100).round(1)
  end

  private

  def period_bounds(period)
    case period
    when :week
      [ 7.days.ago, 14.days.ago, 7.days.ago ]
    when :month
      [ 30.days.ago, 60.days.ago, 30.days.ago ]
    else
      raise ArgumentError, "period must be :week or :month"
    end
  end

  def percentage_change(current, previous)
    return current.zero? ? 0.0 : 100.0 if previous.zero?

    ((current - previous).to_f / previous * 100).round(1)
  end
end
