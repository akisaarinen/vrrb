require 'rubygems'
require 'trains'
require 'parser'

class LegInfoFinder
  attr_reader :trains

  def initialize
    @trains = Trains.load_trains
    @parser = VrParser.new
  end

  def realtime_trains_for_leg(from, to)
    trains_with_measure_station = @trains.trains_with_measurable_stations_for_leg(from,to)
    uniq_stations = trains_with_measure_station.map { |twms| twms[:station] }.uniq
    trains_leaving_stations = uniq_stations.map {|station|
      p "Fetching for #{station.name} (#{station.code})"
      @parser.fetch_train_list(station.code)
    }.flatten.uniq
    trains_matching_leg = trains_leaving_stations.select {|train_leaving|
      trains_with_measure_station.find { |twms|
        name_fits = (twms[:train].name == train_leaving["name"])
        dest_fits = (twms[:train].stations.last.name == train_leaving["target"])
        name_fits && dest_fits
      } != nil
    }
    trains_matching_leg
  end
end