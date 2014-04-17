require 'bundler/setup'
require 'sinatra/base'
require 'curb'
require 'multi_json'
require 'chartkick'
require 'date'

class Stats < Sinatra::Base
  TYPE_RACER_API = 'http://data.typeracer.com'

  get '/:username' do
    @username = params[:username]

    http = Curl.get("#{TYPE_RACER_API}/users?id=tr:#{@username}")
    @data = MultiJson.decode(http.body_str, symbolize_keys: true)

    batch_size = 1000
    offset = 0

    @race_data = []
    loop do
      http = Curl.get("#{TYPE_RACER_API}/games?playerId=tr:#{@username}&amp;n=#{batch_size}&amp;offset=#{offset}")
      batch_data = MultiJson.decode(http.body_str, symbolize_keys: true)
      @race_data += batch_data.reverse

      break if batch_data.length < batch_size
    end

    @daily_data = []
    current_year = nil
    current_day = nil
    current_stats = []
    all_data = @race_data.dup

    while (race = all_data.shift)
      time = Time.at(race[:t])
      current_year ||= time.year
      current_day ||= time.yday

      if time.year == current_year && time.yday == current_day
        current_stats << race[:wpm]
      else
        wpm = current_stats.reduce(:+) / current_stats.length
        current_stats = [race[:wpm]]
        @daily_data << [Date.parse(time.to_s).to_s, wpm]

        if all_data.empty?
          wpm = current_stats.reduce(:+) / current_stats.length
          @daily_data << [Date.parse(time.to_s).to_s, wpm]
        end
      end
    end

    erb :user, layout: :application
  end

  not_found do
    status 404
    erb '<h1>Not Found</h1>', layout: :application
  end
end
