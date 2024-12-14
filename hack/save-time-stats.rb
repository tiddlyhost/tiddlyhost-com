#!/usr/bin/ruby

require 'csv'

module Enumerable
  def mean
    sum / count
  end

  def median
    sorted = sort
    midpoint = count / 2
    return sorted[midpoint] if count.odd?
    sorted[midpoint,2].mean
  end

  def above(threshold)
    select { |n| n > threshold }
  end

  def percent_above(threshold)
    100 * above(threshold).count.to_f / count
  end
end

times = Hash.new { |hsh, key| hsh[key] = [] }
start_time = nil
end_time = nil

CSV.parse(STDIN.read, converters: :all) do |timestamp, _, os, seconds|
  times["All"] << seconds
  times[os] << seconds
  start_time ||= timestamp
  end_time = timestamp
end

puts [
  "Start:  #{start_time}",
  "Finish: #{end_time}",
  "",
  headings = sprintf("%9s %8s %8s %5s %5s %5s %5s %9s %7s", "OS", "Avg", "Median", ">10s", ">20s", ">30s", ">120s", "Max", "Count"),
  headings.gsub(/\S/,"-"),
  times.sort_by{|k,v|-v.count}.map do |os, times|
    sprintf("%9s %8.3f %8.3f %4.0f%% %4.0f%% %4.0f%% %4.0f%% %9.3f %7d",
        os,
        times.mean,
        times.median,
        times.percent_above(10.0),
        times.percent_above(20.0),
        times.percent_above(30.0),
        times.percent_above(120.0),
        times.max,
        times.count)
  end,
]
