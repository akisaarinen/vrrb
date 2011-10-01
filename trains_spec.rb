require 'spec_helper'
require 'trains'

describe Trains, "when loaded" do
  trains = Trains.load_trains

  it "loads all known trains" do
    trains.trains.map{|t|t.name}.should == ["Y", "E", "S", "U", "L", "A"]
  end
end

describe Trains, "find trains for legs" do
  trains = Trains.load_trains

  siuntio = trains.find_station_by_name("Siuntio")
  masala = trains.find_station_by_name("Masala")
  kilo = trains.find_station_by_name("Kilo")
  lpv = trains.find_station_by_name("Leppävaara")
  ilmala = trains.find_station_by_name("Ilmala")
  pasila = trains.find_station_by_name("Pasila")
  hki = trains.find_station_by_name("Helsinki")

  it "all trains from Kilo to Helsinki" do
    trains.trains_for_leg(kilo, hki).map{|t|t.name}.should == ["E", "S", "U", "L"]
  end

  it "all trains from Siuntio to Pasila" do
    trains.trains_for_leg(siuntio, pasila).map{|t|t.name}.should == ["Y"]
  end

  it "all trains from Siuntio to Kilo" do
    trains.trains_for_leg(siuntio, kilo).map{|t|t.name}.should == []
  end

  it "all trains from Masala to Ilmala" do
    trains.trains_for_leg(masala, ilmala).map{|t|t.name}.should == ["L"]
  end

  it "all trains from Leppävaara to Helsinki" do
    trains.trains_for_leg(lpv, hki).map{|t|t.name}.should == ["Y", "E", "S", "U", "L", "A"]
  end
end

describe Trains, "find best measurable stations for legs" do
  trains = Trains.load_trains

  y_train = trains.find_train_by_name("Y")
  s_train = trains.find_train_by_name("S")
  e_train = trains.find_train_by_name("E")
  u_train = trains.find_train_by_name("U")
  l_train = trains.find_train_by_name("L")

  karjaa = trains.find_station_by_name("Karjaa")
  siuntio = trains.find_station_by_name("Siuntio")
  kkn = trains.find_station_by_name("Kirkkonummi")
  espoo = trains.find_station_by_name("Espoo")
  kilo = trains.find_station_by_name("Kilo")
  lpv = trains.find_station_by_name("Leppävaara")
  ilmala = trains.find_station_by_name("Ilmala")
  hki = trains.find_station_by_name("Helsinki")

  it "all trains from Kilo to Helsinki" do
    trains.trains_with_measurable_stations_for_leg(kilo, hki).should ==
        [{:train => e_train, :station => espoo},
         {:train => s_train, :station => espoo},
         {:train => u_train, :station => espoo},
         {:train => l_train, :station => espoo}]
  end

  it "all trains from Ilmala to Kirkkonummi" do
    trains.trains_with_measurable_stations_for_leg(ilmala, kkn).should ==
        [{:train => l_train, :station => hki}]
  end

  it "all trains from Siuntio to Leppävaara" do
    trains.trains_with_measurable_stations_for_leg(siuntio, lpv).should ==
        [{:train => y_train, :station => karjaa}]
  end


  it "all trains from Leppävaara to Kilo" do
    trains.trains_with_measurable_stations_for_leg(lpv, kilo).should ==
        [{:train => e_train, :station => lpv},
         {:train => s_train, :station => lpv},
         {:train => u_train, :station => lpv},
         {:train => l_train, :station => lpv}]
  end
end
