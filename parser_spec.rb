require 'parser'
require 'mocha'

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
    trains.should_not == []
  end

  def empty_page
      ""
  end

  def default_page
    read_test_file("haku.action")
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
end