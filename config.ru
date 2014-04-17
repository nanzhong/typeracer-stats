#\ -s puma
require 'bundler/setup'
require 'rack/parser'
require 'multi_json'
require './stats'

use Rack::Parser, :parsers => {
  'application/json' => Proc.new { |body| ::MultiJson.decode body }
}

run Stats
