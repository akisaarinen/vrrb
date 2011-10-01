require 'spec_helper'
require 'leg_info_finder'

describe LegInfoFinder, "when loaded" do
  lif = LegInfoFinder.new
  trains = lif.trains

  it "loads some real-time data for Leppävaara-Huopalahti" do
    hki = lif.trains.find_station_by_name("Leppävaara")
    lpv = lif.trains.find_station_by_name("Huopalahti")
    rtt = lif.realtime_trains_for_leg(hki,lpv)
    rtt.each { |t|
      p "#{t["name"]} (#{t["id"]}) to '#{t["target"]}'"
    }
  end

  it "loads some real-time data for Huopalahti-Leppävaara" do
    hki = lif.trains.find_station_by_name("Huopalahti")
    lpv = lif.trains.find_station_by_name("Leppävaara")
    rtt = lif.realtime_trains_for_leg(hki,lpv)
    rtt.each { |t|
      p "#{t["name"]} (#{t["id"]}) to '#{t["target"]}'"
    }
  end
end