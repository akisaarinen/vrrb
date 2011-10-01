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
  attr_accessor :trains, :all_known_stations
  def initialize(measured_stations, trains)
    @measured_stations = measured_stations
    @trains = trains
    @all_known_stations = find_all_known_stations(trains)
  end

  def trains_leaving_from(station)
    trains.select {|t| t.stations.include?(station) }
  end

  def find_station_by_name(name)
    i = @all_known_stations.index {|s| s.name == name }
    if i != nil
      @all_known_stations[i]
    else
      nil
    end
  end

  def self.load_trains
    routes = YAML.load_file("routes.yml")

    measured_stations = routes["measured_stations"].map { |s|
      Station.new(s["name"], s["code"])
    }
    other_stations = []

    trains = routes["trains"].map { |r|
      stations = r["stations"].map { |station_name|
        measured_station_index = measured_stations.index{|s| s.code == station_name }
        if measured_station_index != nil
          measured_stations[measured_station_index]
        else
          other_station_index = other_stations.index{|s| s.name == station_name }
          if other_station_index != nil
            other_stations[other_station_index]
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

t = Trains.load_trains
t.all_known_stations.each {|s| p "#{s.name} => #{s.code}" }

kilo = t.find_station_by_name("Leppävaara")

p t.trains_leaving_from(kilo).map{|t|t.name}
