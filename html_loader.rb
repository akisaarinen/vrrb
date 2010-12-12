require 'rubygems'
require 'uri'
require 'net/http'

class VrHtmlLoader
  def initialize
    @base_url = "http://service.vr.fi"
    @train_list_url = "/juku/haku.action?lang=fi&junalaji=ll"
    @train_info_url = "/juku/juna.action?junalaji=ll&lang=fi"
  end

  def get_main_page(station)
    uri = URI.parse(@base_url + @train_list_url)
    Net::HTTP.get uri
  end

  def post_train_list(station, post_uri)
    uri = URI.parse(@base_url + post_uri)
    params = {
      "lang" => "fi",
      "junalaji" => "ll",
      "asema" => station
    }
    post_reply = Net::HTTP.post_form(uri, params)
    post_reply.body
  end

  def get_train_info_by_id(train_id)
    uri = URI.parse(@base_url + @train_info_url + "&junanro=" + train_id)
    Net::HTTP.get uri
  end
end
