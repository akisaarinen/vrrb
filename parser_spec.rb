require 'rubygems'
require 'parser'
require 'mocha'
require 'rspec'

describe VrParser, "#fetch_train_list" do
  html_loader = VrHtmlLoader.new
  parser = VrParser.new
  parser.html_loader = html_loader

  it "does nothing with empty main page" do
    html_loader.stubs(:get_main_page).returns(empty_page)
    trains = parser.fetch_train_list("EPO")
    trains.should == []
  end

  it "fetches list of trains in Espoo" do
    html_loader.stubs(:get_main_page).returns(default_page)
    html_loader.stubs(:post_train_list).returns(read_test_file("station.espoo.with-notes"))
    trains = parser.fetch_train_list("EPO")
    trains.map { |t| t["name"] }.should == ["U", "S", "S", "U"]
    trains.map { |t| t["id"] }.should == ["8552", "8561", "8556", "8565"]
    trains.map { |t| t["target"] }.should == ["Helsinki", "Kirkkonummi", "Helsinki", "Kirkkonummi"]
  end

  it "fetches list of trains in Espoo with empty rows" do 
    html_loader.stubs(:get_main_page).returns(default_page)
    html_loader.stubs(:post_train_list).returns(read_test_file("station.espoo.with-empty-row"))
    trains = parser.fetch_train_list("EPO")
    trains.map { |t| t["name"] }.should == ["U", "U"]
    trains.map { |t| t["id"] }.should == ["8587", "8584"]
    trains.map { |t| t["target"] }.should == ["Kirkkonummi", "Helsinki"]
  end
  
  it "fetches list of trains in Espoo with lots of trains" do 
    html_loader.stubs(:get_main_page).returns(default_page)
    html_loader.stubs(:post_train_list).returns(read_test_file("station.espoo.many-trains"))
    trains = parser.fetch_train_list("EPO")
    trains.map { |t| t["name"] }.should == ["L", "L", "S", "E", "E", "U", "U", "E", "E", "U"]
    trains.map { |t| t["id"] }.should == ["8416", "8424", "8465", "8318", "8323", "8464", "8471", "8324", "8325", "8466"]
    trains.map { |t| t["target"] }.should == ["Helsinki", "Helsinki", "Kirkkonummi", "Helsinki", "Kauklahti", "Helsinki", "Kirkkonummi", "Helsinki", "Kauklahti", "Helsinki"]
  end

  def empty_page
      ""
  end

  def default_page
    read_test_file("haku.action")
  end
end

describe VrParser, "#fetch_single_train" do
  html_loader = VrHtmlLoader.new
  parser = VrParser.new
  parser.html_loader = html_loader

  it "parses information for single train from helsinki to kirkkonummi" do
    html_loader.stubs(:get_train_info_by_id).returns(read_test_file("train.s.helsinki-kirkkonummi"))
    info = parser.fetch_single_train("anyId")

    info["id"].should == "8551"
    info["name"].should == "S"
    info["url"].should == "http://service.vr.fi/juku/juna.action?lang=fi&junalaji=ll&junanro=8551"
    info["update_time"].should == "12.12.2010, klo 19:40."
    info["source"].should == "Helsinki"
    info["target"].should == "Kirkkonummi"
  end
  
  it "parses information for single train from helsinki to karjaa" do
    html_loader.stubs(:get_train_info_by_id).returns(read_test_file("train.y.helsinki-karjaa"))
    info = parser.fetch_single_train("anyId")

    info["id"].should == "8553"
    info["name"].should == "Y"
    info["url"].should == "http://service.vr.fi/juku/juna.action?lang=fi&junalaji=ll&junanro=8553"
    info["update_time"].should == "14.12.2010, klo 19:45."
    info["source"].should == "Helsinki"
    info["target"].should == "Karjaa"
  end
end


def read_test_file(filename)
  f = File.new("testhtml/" + filename + ".html")
  contents = ""
  while (line = f.gets)
    contents += line
  end
  f.close
  contents
end
