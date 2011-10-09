require 'rubygems'
require 'uri'
require 'net/http'
require 'nokogiri'

require './html_loader.rb'
require './trains.rb'

class RealTimeStation < Station
  attr_reader :scheduled_arrival, :actual_arrival, :scheduled_departure, :actual_departure
  def initialize(name, code, scheduled_arrival, actual_arrival, scheduled_departure, actual_departure)
    super(name, code)
    @scheduled_arrival = scheduled_arrival
    @actual_arrival = actual_arrival
    @scheduled_departure = scheduled_departure
    @actual_departure = actual_departure
  end

  def to_json(*a)
    {
        :name => @name,
        :code => @code,
        :scheduled_arrival => @scheduled_arrival,
        :actual_arrival => @actual_arrival,
        :scheduled_departure => @scheduled_departure,
        :actual_departure => @actual_departure
    }.to_json(*a)
  end

  def ==(other)
    super.==(other) &&
        other.scheduled_arrival == @scheduled_arrival &&
        other.actual_arrival == @actual_arrival &&
        other.scheduled_departure == @scheduled_departure &&
        other.actual_departure == @actual_departure
  end
end

class RealTimeTrain < Train
  attr_reader :id, :url, :update_time
  def initialize(id, url, name, stations, update_time, full_info)
    super(name, stations)
    @id = id
    @url = url
    @update_time = update_time
    @full_info = full_info
  end

  def source
    @stations.first
  end

  def target
    @stations.last
  end

  def last_confirmed_departure_station
    @stations.reverse.find {|s|
      s.actual_departure != nil &&
      s.actual_departure != ""
    } || @stations.first
  end

  def to_json(*a)
    {
        :id => @id,
        :url => @url,
        :name => @name,
        :stations => @stations,
        :update_time => @update_time,
        :full_info => @full_info
    }.to_json(a)
  end

  def ==(other)
    super.==(other) &&
        other.id == @id &&
        other.url == @url &&
        other.update_time == @update_time
  end
end

class VrParser
  attr_accessor :html_loader

  def initialize
    @base_url = "http://ext-service.vr.fi"
    @html_loader = VrHtmlLoader.new
  end

  def fetch_train_list(station)
    r = @html_loader.get_main_page(station)
    if m = /action="([^"]+)"/.match(r)
      post_reply = @html_loader.post_train_list(station, m[1])
      #puts "Processing station " + station
      doc = Nokogiri::HTML(post_reply)
      departure_table = doc.css('table.kulkutiedot').first

      rows = departure_table.css('tr').to_a.delete_if { |tr| tr['class'] == 'table_header' }

      rows.map { |row| 
        #puts "Processing " + row.to_s
        link = row.css('a.lahi').first
        if link 
          target = row.css('td')[4].content
          train_url = link['href']
          train_id = find_id(train_url)
          train_name = link.content
          RealTimeTrain.new(train_id,
            train_url,
            train_name,
            [Station.new(target, nil)],
            nil,
            false)
        else
          nil
        end
      }.select {|r| r != nil }
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

    stations = []
    update_info = doc.css('table.header span.middle').first.content
    update_time = /viimeksi(.*)Osasta/m.match(update_info)[1].strip

    #puts "info: '#{update_info}', time: '#{update_time}'"

    doc.css('table.kulkutiedot tr').each { |tr|
      station_node = tr.css('td.first_border a').first || tr.css('td.first_border span').first
      sched_elems = tr.css('td').map{|e| e.content.strip}
      if station_node
        stations.push({
          :name => station_node.content.strip,
          :scheduled_arrival => sched_elems[1].sub(/[^0-9:]+/, ""),
          :actual_arrival => sched_elems[2].sub(/[^0-9:]+/, "")
        })
        # For first station, all data in first row
        if stations.length == 1
          stations.last[:scheduled_departure] = sched_elems[4].sub(/[^0-9:]+/, "")
          stations.last[:actual_departure] = sched_elems[5].sub(/[^0-9:]+/, "")
        end
      # For other stations, data is in next row without station
      elsif stations.length > 0
        stations.last[:scheduled_departure] = sched_elems[4].sub(/[^0-9:]+/, "")
        stations.last[:actual_departure] = sched_elems[5].sub(/[^0-9:]+/, "")
      end
    }

    station_objects = stations.map { |s|
      RealTimeStation.new(s[:name],
                          s[:code],
                          empty_to_nil(s[:scheduled_arrival]),
                          empty_to_nil(s[:actual_arrival]),
                          empty_to_nil(s[:scheduled_departure]),
                          empty_to_nil(s[:actual_departure]))
    }

    RealTimeTrain.new(train_id,
      train_url,
      train_name,
      station_objects,
      update_time,
      true)
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

  def empty_to_nil(s)
    if s == ""
      nil
    else
      s
    end
  end

end
