require 'sinatra'
require 'bundler/setup'
require 'rubygems'

get '/' do
	"Hello"
end

post '/' do
	if params[:type] == "url_verification"
		return params[:challenge]
	end 
end

