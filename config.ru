require 'sinatra'
require 'mustache/sinatra'
require 'xtract.rb'
require 'lib/amazon_zoom_extractor'

Sinatra::Application.class_eval do
  register Mustache::Sinatra
end
run Sinatra::Application