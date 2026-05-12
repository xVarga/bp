require 'net/http'

module Api
  module V1
    class BysquareController < ApplicationController
      def decode
        payload = params[:payload]
        return render json: { error: 'payload je povinný' }, status: :bad_request if payload.blank?

        uri = URI('https://api.bysquare.com/read')
        request = Net::HTTP::Post.new(uri)
        request['Authorization'] = ENV['BYSQUARE_API_KEY']
        request['Content-Type'] = 'application/json'
        request.body = { payload: payload }.to_json

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(request)
        end

        render json: JSON.parse(response.body)
      rescue => e
        render json: { error: e.message }, status: :internal_server_error
      end
    end
  end
end