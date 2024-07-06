# frozen_string_literal: true

module AdminChartData
  private

  def chart_data_subscribers
    day_range('2023-02-25') do |d|
      Pay::Subscription.where.not(status: 'canceled').
        where('created_at <= ? AND current_period_end >= ?', d, d)
    end
  end

  def chart_data_signups_per_day
    # (Doesn't count deleted accounts)
    day_range do |d|
      User.signed_in_more_than(0).
        where('created_at >= ? AND created_at <=?', d.prev_day, d)
    end
  end

  def chart_data_total_users
    # (Doesn't count deleted accounts)
    day_range do |d|
      User.signed_in_more_than(1).
        where('created_at <= ?', d)
    end
  end

  KNOWN_CHARTS = %w[
    subscribers
    signups_per_day
    total_users
  ]

  DEFAULT_CHART = KNOWN_CHARTS.first

  #---------------------------------------------------------------------------

  def chart_data(chart_param)
    chart_name = KNOWN_CHARTS.include?(chart_param) ? chart_param : DEFAULT_CHART
    {
      name: chart_name,
      title: chart_name.titleize,
      data: send("chart_data_#{chart_name}"),
    }
  end

  # Fixme: This is slow and inefficient
  def day_range(from = '2021-02-12')
    (Date.parse(from)..Date.today).map do |d|
      # First column is X axis, second column is Y axis
      [d.to_s, yield(d.to_time).count]
    end
  end
end
