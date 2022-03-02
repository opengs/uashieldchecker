# frozen_string_literal: true

require 'sinatra'
require 'open-uri'
require 'net/http'

ENV['http_proxy'] = "http://Us7as5:UcTYk5YNmEg2@hproxy.site:11858"

SITES_GITHUB_LOCATION   = 'https://raw.githubusercontent.com/opengs/uashieldtargets/master/sites.json'
STATUS_COLORS           = { up: 'green', down: 'red', blocked: 'orange' }.freeze

WITH_PROXY = true # Change this to true when not running from a native server

def load_sites
  JSON.parse(URI.parse(SITES_GITHUB_LOCATION).open(&:read))
end

def response_code_to_status(code)
  if code >= 200 && code < 400
    :up
  elsif code >= 400 && code < 500
    :blocked
  else
    :down
  end
end

def run_test_request(url)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true if uri.scheme == 'https'
  http.open_timeout = 1
  http.read_timeout = 2
  http.ssl_timeout  = 2
  response = http.start { |http| http.request(Net::HTTP::Get.new(uri.request_uri)) }
  response.code.to_i
rescue StandardError
  000
end

get '/' do
  stream do |out|
    out << "<!DOCTYPE html><html><head><title>UA Shield Status</title></head><body><h1 style='text-align: center'>UA Shield Status</h1>"
    out << "<div style='display: flex; flex-direction: column-reverse; flex-wrap: wrap;'>"
    load_sites.each do |site|
      page          = site['page']
      response_code = run_test_request(site['page'])
      status        = response_code_to_status(response_code)

      out << <<~HTML
        <div style='display: flex; flex-direction: row; flex-wrap: wrap; padding: 1.4rem; border: 1px solid #ccc; background-color: #{STATUS_COLORS[status]}'>
          <span style='margin: auto;'>#{page} => #{response_code == 0 ? "Timed Out" : response_code}</span>
        </div>
      HTML
    end

    out << "</div></body></html>"
  end
end
