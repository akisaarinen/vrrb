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
trains = leg_info_finder.trains

get '/' do
  redirect '/find'
end

get '/api/stations.json' do
  headers 'Content-Type' => "application/json; charset=utf-8"
  trains.all_known_stations.to_json
end

get '/api/station/:station.json' do
  headers 'Content-Type' => "application/json; charset=utf-8"
  vr_parser.fetch_train_list(params[:station]).to_json
end

get '/api/train/:id.json' do
  headers 'Content-Type' => "application/json; charset=utf-8"
  vr_parser.fetch_single_train(params[:id]).to_json
end

get '/api/trains/search.json' do
  headers 'Content-Type' => "application/json; charset=utf-8"
  from = leg_info_finder.trains.find_station_by_name(params[:from])
  to = leg_info_finder.trains.find_station_by_name(params[:to])
  leg_info_finder.realtime_trains_for_leg(from, to).to_json
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
  @trains = realtime_train_list.map { |t|
    vr_parser.fetch_single_train(t.id)
  }
  erb :show_single
end

# reqs:
# ruby1.8-dev
# libxslt-ruby
# libxml2-dev
# libxslt1-dev
