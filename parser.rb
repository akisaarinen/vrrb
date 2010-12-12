require 'rubygems'
require 'uri'
require 'net/http'
require 'nokogiri'

require 'html_loader.rb'

class VrParser
  attr_accessor :html_loader

  def initialize
    @base_url = "http://service.vr.fi"
    @html_loader = VrHtmlLoader.new
  end


  def fetch_train_list(station)
    r = @html_loader.get_main_page(station)
    if m = /action="([^"]+)"/.match(r)
      post_reply = @html_loader.post_train_list(station, m[1])
      doc = Nokogiri::HTML(post_reply)
      departure_table = doc.css('table.kulkutiedot').first
      departure_table.css('a').map { |a|
        { 'name' => a.content, 'url' => a['href'] }
      }
    else
      []
    end
  end

  def fetch_single_train(train_name, train_url)
    r = @html_loader.get_train_info(train_url)
    doc = Nokogiri::HTML(r)

    stations = []
    update_info = doc.css('table.header span.middle').first.content
    update_time = /viimeksi(.*)Osasta/m.match(update_info)[1].strip
    puts "info: '#{update_info}', time: '#{update_time}'"
    doc.css('table.kulkutiedot tr').each { |tr|
      station = tr.css('td.first_border a').first || tr.css('td.first_border span').first
      elems = tr.css('td').map{|e| e.content.strip}
      if station
        stations.push({
          'name' => station.content.strip,
          'arr_sched' => elems[1].sub(/[^0-9:]+/, ""),
          'arr_actual' => elems[2].sub(/[^0-9:]+/, "")
        })
        # For first station, all data in first row
        if stations.length == 1
          stations.last['dep_sched'] = elems[4].sub(/[^0-9:]+/, "")
          stations.last['dep_actual'] = elems[5].sub(/[^0-9:]+/, "")
        end
      # For other stations, data is in next row without station
      elsif stations.length > 0
        stations.last['dep_sched'] = elems[4].sub(/[^0-9:]+/, "")
        stations.last['dep_actual'] = elems[5].sub(/[^0-9:]+/, "")

      end
    }
    target_station = stations.last['name']
    [train_name, @base_url + train_url, update_time, target_station, stations]
  end

  def fetch_all_trains(station_code)
    fetch_train_list(station_code).map { |t|
      fetch_single_train(t['name'], t['url'])
    }
  end
end