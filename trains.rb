require 'rubygems'
require 'yaml'

class Station
  attr_reader :name, :code
  def initialize(name, code)
    @name = name
    @code = code
  end
end

class Train
  attr_reader :name, :stations
  def initialize(name, stations)
    @name = name
    @stations = stations
  end
end

class Trains
  def self.load_trains
    routes = YAML.load_file("routes.yml")

    measured_stations = routes["measured_stations"].map { |s|
      Station.new(s["name"], s["code"])
    }

    trains = routes["trains"].map { |r|
      stations = r["stations"].map { |station|
        measured_station_index = measured_stations.index{|m| m.code == station }
        if measured_station_index != nil
          measured_stations[measured_station_index]
        else
          Station.new(station, nil)
        end
      }
      Train.new(r["name"], stations)
    }

    p trains
  end
end

p Trains.load_trains
