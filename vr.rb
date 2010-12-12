require 'rubygems'
require 'sinatra'
require 'uri'
require 'net/http'
require 'nokogiri'
require 'yaml'

require 'parser.rb'

$config = YAML.load_file("vr.yml")
vr_parser = VrParser.new

get '/' do
  @routes = $config.keys
  erb :show_all 
end

get '/trains/:route' do
  route_config = $config[params[:route]]
  
  @select_by_target = (route_config["select_by_target"] == true)
  @reference_station_code = route_config["reference_station_code"]
  @local_station = route_config["local_station"]
  @target_station = route_config["target_station"]
  @source_station = route_config["source_station"]

  def train_selector(select_by_target, target_station, source_station, source, target)
    if select_by_target
      target == target_station
    else
      source == source_station
    end
  end

  trains = vr_parser.fetch_all_trains(@reference_station_code)
  selected_trains = trains.select { |t|
    train_selector(@select_by_target, @target_station, @source_station, t["stations"].first["name"], t["target"])
  }

  @trains = selected_trains.map { |t|
    name = t["name"]
    url = t["url"]
    update_info = t["update_time"]
    target = t["target"]
    stations = t["stations"]

    last_station = stations.reverse.find { |s| s['dep_actual'] != nil && s["dep_actual"] != "" } || stations.first
    kilo = stations.find { |s| s['name'] == @local_station }
    [name, url, update_info, target, last_station, kilo]
  }
  erb :show_single
end

# reqs:
# ruby1.8-dev
# libxslt-ruby
# libxml2-dev
# libxslt1-dev
