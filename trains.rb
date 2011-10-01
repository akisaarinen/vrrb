require 'rubygems'
require 'yaml'

class Station
  attr_reader :name, :code
  def initialize(name, code)
    @name = name
    @code = code
  end

  def measurable?
    @code != nil
  end
end

class Train
  attr_reader :name, :stations
  def initialize(name, stations)
    @name = name
    @stations = stations
  end

  def reverse
    Train.new(@name, stations.reverse)
  end

  def ==(other)
    other != nil && other.name == @name && other.stations == @stations
  end
end

class Trains
  attr_accessor :trains, :all_known_stations
  def initialize(measured_stations, trains)
    @measured_stations = measured_stations
    @trains = trains
    @all_known_stations = find_all_known_stations(trains)
  end

  def trains_leaving_from(station)
    trains.select {|t| t.stations.include?(station) }
  end

  def trains_for_leg(from, to)
    trains.select {|t|
      t.stations.include?(from) &&
      t.stations.include?(to)
    }.map {|t|
      if t.stations.index(from) <= t.stations.index(to)
        t
      else
        t.reverse
      end
    }
  end

  def trains_with_measurable_stations_for_leg(from, to)
    throw "Same source and destinations" if from == to
    trains_for_leg(from, to).map {|train|
      from_index = train.stations.index(from)
      measurable_before_from = train.stations.
          select { |s| s.measurable? }.
          select {|s| train.stations.index(s) <= from_index }
      best_measurable_station = measurable_before_from.last
      { :train => train,
        :station => best_measurable_station }
    }
  end

  def find_train_by_name(name)
    @trains.find {|t| t.name == name }
  end

  def find_station_by_name(name)
    @all_known_stations.find {|s| s.name == name }
  end

  def self.load_trains
    routes = YAML.load_file("routes.yml")

    measured_stations = routes["measured_stations"].map { |s|
      Station.new(s["name"], s["code"])
    }
    other_stations = []

    trains = routes["trains"].map { |r|
      stations = r["stations"].map { |station_name|
        measured_station = measured_stations.find{|s| s.code == station_name }
        if measured_station != nil
          measured_station
        else
          other_station = other_stations.find{|s| s.name == station_name }
          if other_station != nil
            other_station
          else
            station = Station.new(station_name, nil)
            other_stations.push(station)
            station
          end
        end
      }
      Train.new(r["name"], stations)
    }
    Trains.new(measured_stations, trains)
  end

private
  def find_all_known_stations(trains)
    trains.map { |t| t.stations }.flatten.uniq.sort {|t1,t2| t1.name <=> t2.name }
  end

end