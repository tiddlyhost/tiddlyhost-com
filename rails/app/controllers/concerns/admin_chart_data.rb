module AdminChartData
  private

  def chart_data_subscribers
    day_range(from: SUBSCRIBERS_EPOCH) do |d|
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

  def chart_data_signups_per_week
    # (Doesn't count deleted accounts)
    day_range(from: USERS_EPOCH, interval: 7) do |d|
      User.signed_in_more_than(0).
        where('created_at >= ? AND created_at <=?', d.prev_week, d)
    end
  end

  KNOWN_CHARTS = %w[
    subscribers
    signups_per_day
    signups_per_week
    total_users
  ].freeze

  DEFAULT_CHART = KNOWN_CHARTS.first

  # Make these both on a Sunday so the X-axis rendering matches the data better
  USERS_EPOCH = '2021-02-07'
  SUBSCRIBERS_EPOCH = '2023-02-19'

  #---------------------------------------------------------------------------

  def chart_data(chart_param)
    chart_name = KNOWN_CHARTS.include?(chart_param) ? chart_param : DEFAULT_CHART
    {
      name: chart_name,
      title: chart_name.titleize,
      data: send("chart_data_#{chart_name}"),
    }
  end

  # FIXME: This could probably be implemented using a single grouped
  # db query rather than doing a separate query for each interval
  def day_range(from: USERS_EPOCH, interval: 1)
    start_date = Date.parse(from)
    end_date = Date.today

    x_axis = []
    x = start_date
    while x < end_date
      x_axis << x
      x += interval
    end

    x_axis.map do |x_val|
      y_val = yield(x_val.to_time).count
      [x_val.to_s, y_val]
    end
  end
end
