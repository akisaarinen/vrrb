require 'rubygems'
require 'sinatra'
require 'uri'
require 'net/http'
require 'nokogiri'

$base_url = "http://service.vr.fi"

def fetch_train_list(station)
  search_url = "/juku/haku.action?lang=fi&junalaji=ll"
  uri = URI.parse($base_url + search_url)
  r = Net::HTTP.get uri
  if m = /action="([^"]+)"/.match(r)
    post_uri = URI.parse($base_url + m[1])
    post_params = {
      "lang" => "fi",
      "junalaji" => "ll",
      "asema" => station
    }
    post_reply = Net::HTTP.post_form(post_uri, post_params)
    doc = Nokogiri::HTML(post_reply.body)
    departure_table = doc.css('table.kulkutiedot').first
    departure_table.css('a').map { |a|
      { 'name' => a.content, 'url' => a['href'] }
    }
  else
    []
  end
end

def fetch_single_train(train_name, train_url)
  uri = URI.parse($base_url + train_url)
  r = Net::HTTP.get uri
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
  [train_name, $base_url + train_url, update_time, target_station, stations]
end

def fetch_all_trains(station_code) 
  fetch_train_list(station_code).map { |t|
    fetch_single_train(t['name'], t['url'])
  }
end


def train_selector(source, target)
  puts "source: #{source}, target: #{target}"
  source == "Helsinki"
end


get '/' do
  reference_station_code = "EPO"
  local_station = "Kilo"

  trains = fetch_all_trains(reference_station_code)
  selected_trains = trains.select { |n, url, u, t, s| train_selector(s.first["name"], t) }

  @trains = selected_trains.map { |name, url, update_info, target, stations|
    last_station = stations.reverse.find { |s| s['dep_actual'] != nil && s["dep_actual"] != "" } || stations.first
    kilo = stations.find { |s| s['name'] == local_station }
    [name, url, update_info, target, last_station, kilo]
  }
  erb :show
end

# reqs:
# ruby1.8-dev
# libxslt-ruby
# libxml2-dev
# libxslt1-dev
