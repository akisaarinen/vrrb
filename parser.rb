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

      rows = departure_table.css('tr').to_a.delete_if { |tr| tr['class'] == 'table_header' }

      return rows.map { |row| 
        link = row.css('a.lahi').first
        target = row.css('td')[4].content
        train_url = link['href']
        train_id = find_id(train_url)
        {
          'name' => link.content,
          'id' => train_id,
          'url' => train_url,
          'target' => target
        }
      } 
    else
      []
    end
  end

  def fetch_single_train(original_id)
    r = @html_loader.get_train_info_by_id(original_id)
    doc = Nokogiri::HTML(r)

    new_search_url = doc.css('table.kulkutiedot_footer td.search a').first['href']
    train_id = find_id(new_search_url)
    train_url = @base_url + "/juku/juna.action?lang=fi&junalaji=ll&junanro=" + train_id

    train_header_info = doc.css('table.header th.alaots').first.content

    # What a nice, clean regex :)
    header_regex = /\s+([a-zA-Z])\s*:\s*([\S]+)[^-]+-[\s]+([\S]+)/.match(train_header_info)

    train_name = header_regex[1]
    train_source = header_regex[2]
    train_target = header_regex[3]

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

    { "id" => train_id,
      "name" => train_name,
      "url" => train_url,
      "update_time" => update_time,
      "source" => train_source,
      "target" => train_target,
      "stations" => stations }

  end

  def fetch_all_trains(station_code)
    fetch_train_list(station_code).map { |t|
      fetch_single_train(t['id'])
    }
  end

private

  def find_id(train_url)
    /junanro=([0-9]+)/.match(train_url)[1]
  end

end
