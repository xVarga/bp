require 'net/http'

module Api
  module V1
    class EkasaController < ApplicationController
      def find
        receipt_id = params[:receiptId]
        return render json: { error: 'receiptId je povinný' }, status: :bad_request if receipt_id.blank?

        response = Net::HTTP.post(
          URI('https://ekasa.financnasprava.sk/mdu/api/v1/opd/receipt/find'),
          { receiptId: receipt_id }.to_json,
          'Content-Type' => 'application/json',
          'Origin' => 'https://opd.financnasprava.sk',
          'Referer' => 'https://opd.financnasprava.sk/'
        )

        data = JSON.parse(response.body)
        render json: data
      rescue => e
        render json: { error: e.message }, status: :internal_server_error
      end
    end
  end
end