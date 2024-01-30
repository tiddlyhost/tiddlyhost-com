
module AdminChartData

  private

  def chart_data(which)
    send("chart_data_#{which}")
  end

  def chart_data_subscriber_count
    (Date.parse('2023-02-25')..Date.today).map do |d|
      subscribers = Pay::Subscription.
          where('created_at <= ? AND current_period_end >= ?', d.to_time, d.to_time).
          where.not(status: 'canceled')

      # First column is X axis, second column is Y axis
      [ d.to_s, subscribers.count ]
    end
  end

end
