require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'uri'
require 'net/http'
require 'nokogiri'
require 'yaml'
require 'json'

require './parser'
require './leg_info_finder'

vr_parser = VrParser.new
leg_info_finder = LegInfoFinder.new

get '/' do
  redirect '/find'
end

get '/api/station/:station.json' do
  headers 'Content-Type' => "application/json; charset=utf-8"
  vr_parser.fetch_train_list(params[:station]).to_json
end

get '/api/train/:id.json' do
  headers 'Content-Type' => "application/json; charset=utf-8"
  vr_parser.fetch_single_train(params[:id]).to_json
end

get '/view' do
  erb :ajaxview
end

get '/find' do
  @stations = leg_info_finder.trains.all_known_stations
  @default_from = @stations.find { |s| s.name == "Kilo" }
  @default_to = @stations.find { |s| s.name == "Helsinki" }
  erb :find
end

get '/showtrains' do
  @from = leg_info_finder.trains.find_station_by_name(params[:from])
  @to = leg_info_finder.trains.find_station_by_name(params[:to])

  realtime_train_list = leg_info_finder.realtime_trains_for_leg(@from, @to)
  realtime_train_details = realtime_train_list.map { |t|
    vr_parser.fetch_single_train(t["id"])
  }

  @trains = realtime_train_details.map { |t|
    name = t["name"]
    url = t["url"]
    update_info = t["update_time"]
    target = t["target"]
    stations = t["stations"]
    last_station = stations.reverse.find { |s| s['dep_actual'] != nil && s["dep_actual"] != "" } || stations.first
    from_station = stations.find { |s| s['name'] == @from.name }
    [name, url, update_info, target, last_station, from_station]
  }
  erb :show_single
end

# reqs:
# ruby1.8-dev
# libxslt-ruby
# libxml2-dev
# libxslt1-dev
