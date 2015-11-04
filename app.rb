require 'sinatra'
require 'rufus-scheduler'
require_relative 'scrape'

class ScrapeApp < Sinatra::Base

	set :run, true
	set :server, 'webrick'
	
  output_file = 'closure_coordinates.txt'

  get '/' do 'hi' end

  get '/closures' do
    send_file output_file
  end

  get '/intersections_with_closures' do
    
  end

  seconds_per_day = 24 * 60 * 60
  seconds_in_four_minutes = 4 * 60
  day = "#{seconds_per_day}s"
  four_minutes = "#{seconds_in_four_minutes}s"

  scheduler = Rufus::Scheduler.new
  scheduler.every day, :first_in => 0.1 do
    File.open('closure_coordinates.txt', 'a+') do |file|
      unless is_refreshing?
        file.truncate 0
        file.puts street_closure_report
      else
        p 'System is refreshing.'
      end
    end
  end

  keep_alive = Rufus::Scheduler.new
  keep_alive.every four_minutes, :first_in => 0.1 do
    p Net::HTTP.get(URI.parse(URI.encode("https://streetscrape.herokuapp.com/")))
    p Time.now.inspect
  end

	run! if app_file == $0
end