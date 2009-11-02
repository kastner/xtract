require 'sinatra'
require 'mustache/sinatra'
require 'xtract.rb'
require 'lib/amazon_zoom_extractor'

log = File.new("log/sinatra.log", "a")
$stdout.reopen(log)
$stderr.reopen(log)

Sinatra::Application.class_eval do
  register Mustache::Sinatra
end
run Sinatra::Application