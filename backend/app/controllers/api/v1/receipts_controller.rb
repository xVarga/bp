module Api
    module V1
        class ReceiptsController < ApplicationController
            before_action :authenticate_user!

            #GET /api/v1/receipts
            def index
                receipts = @current_user.receipts.order(issued_at: :desc)
                render json: receipts.map { |r| receipt_json(r) }
            end

            #GET /api/v1/receipts/:id
            def show
                receipt = @current_user.receipts.find(params[:id])
                render json: receipt_json(receipt)
            rescue ActiveRecord::RecordNotFound
                render json: { error: 'Bloček nenájdený' }, status: :not_found
            end

            #POST /api/v1/receipts
            def create
                receipt = @current_user.receipts.new(receipt_params)
                if receipt.save
                    render json: receipt_json(receipt), status: :created
                else
                    render json: { errors: receipt.errors.full_messages }, status: :unprocessable_entity
                end
            end

            #DELETE /api/v1/receipts/:id
            def destroy
                receipt = @current_user.receipts.find(params[:id])
                receipt.destroy
                render json: { message: 'Bloček bol vymazaný' }
            rescue ActiveRecord::RecordNotFound
                render json: { error: 'Bloček nenájdený' }, status: :not_found
            end

            private

            def receipt_params
                params.require(:receipt).permit(
                    :merchant_name, :merchant_address, :dic, :ic_dph, :ico, :cash_register_code, :receipt_number, :issued_at, :total_amount, receipt_items_attributes: [
                        :description, :quantity, :unit_price, :total_price
                    ]
                )
            end

            def receipt_json(receipt)
                {
                    id: receipt.id,
                    merchant_name: receipt.merchant_name,
                    merchant_address: receipt.merchant_address,
                    dic: receipt.dic,
                    ic_dph: receipt.ic_dph,
                    ico: receipt.ico,
                    cash_register_code: receipt.cash_register_code,
                    receipt_number: receipt.receipt_number,
                    issued_at: receipt.issued_at,
                    total_amount: receipt.total_amount,
                    items: receipt.receipt_items.map { |item| {
                        id: item.id,
                        description: item.description,
                        quantity: item.quantity,
                        unit_price: item.unit_price,
                        total_price: item.total_price
                    }}
                }
            end
        end
    end
end
