module Api
  module V1
    class InvoicesController < ApplicationController
      before_action :authenticate_user!

      # GET /api/v1/invoices
      def index
        all_versions = @current_user.invoices
        parent_ids = all_versions.pluck(:parent_id).compact

        latest = @current_user.invoices
          .where(is_cancelled: false)
          .where.not(id: parent_ids)

        render json: latest.map { |invoice| invoice_json(invoice) }
      end

      # GET /api/v1/invoices/:id
      def show
        invoice = @current_user.invoices.find(params[:id])
        render json: invoice_json(invoice)
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Faktúra nenájdená' }, status: :not_found
      end

      # POST /api/v1/invoices
      def create
        invoice = @current_user.invoices.new(invoice_params)
        invoice.version = 1
        invoice.is_cancelled = false

        if invoice.save
          render json: invoice_json(invoice), status: :created
        else
          render json: { errors: invoice.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/invoices/:id
      def update
        old_invoice = @current_user.invoices.find(params[:id])

        new_invoice = @current_user.invoices.new(invoice_params)
        new_invoice.version = old_invoice.version + 1
        new_invoice.is_cancelled = false
        new_invoice.parent_id = old_invoice.id

        if new_invoice.save
          render json: invoice_json(new_invoice), status: :created
        else
          render json: { errors: new_invoice.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Faktúra nenájdená' }, status: :not_found
      end

      # DELETE /api/v1/invoices/:id
      def destroy
        invoice = @current_user.invoices.find(params[:id])
        
        
        @current_user.invoices
          .where(parent_id: invoice.id)
          .update_all(parent_id: invoice.parent_id)
        
        invoice.destroy
        render json: { message: 'Verzia bola vymazaná' }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Faktúra nenájdená' }, status: :not_found
      end

      # PATCH /api/v1/invoices/:id/cancel
      def cancel
        invoice = @current_user.invoices.find(params[:id])
        invoice.update(is_cancelled: true)
        render json: invoice_json(invoice)
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Faktúra nenájdená' }, status: :not_found
      end

      # GET /api/v1/invoices/:id/history
      def history
        invoice = @current_user.invoices.find(params[:id])
        
        root = invoice
        while root.parent_id
          root = @current_user.invoices.find(root.parent_id)
        end
        
        all_versions = collect_versions(root)
        
        render json: all_versions.sort_by { |v| v.version }.map { |v| invoice_json(v) }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Faktúra nenájdená' }, status: :not_found
      end

      private

      def collect_versions(invoice)
        versions = [invoice]
        children = @current_user.invoices.where(parent_id: invoice.id)
        children.each do |child|
          versions += collect_versions(child)
        end
        versions
      end

      def invoice_params
        params.require(:invoice).permit(
          :invoice_number, :issue_date, :delivery_date, :total_vat_amount,
          :total_without_vat, :total_with_vat,
          :supplier_id, :customer_id,
          :self_billed, :reverse_charge,
          :travelling_agency, :used_item, :art, :collectibles,
          :vat_exempt,
          invoice_items_attributes: [
            :description, :quantity, :unit_price, :tax_rate, :vat_amount, :total_without_vat, :total_with_vat
          ]
        )
      end

      def invoice_json(invoice)
        {
          id: invoice.id,
          invoice_number: invoice.invoice_number,
          issue_date: invoice.issue_date,
          delivery_date: invoice.delivery_date,
          total_vat_amount: invoice.total_vat_amount,
          total_without_vat: invoice.total_without_vat,
          total_with_vat: invoice.total_with_vat,
          is_cancelled: invoice.is_cancelled,
          version: invoice.version,
          self_billed: invoice.self_billed,
          reverse_charge: invoice.reverse_charge,
          travelling_agency: invoice.travelling_agency,
          used_item: invoice.used_item,
          art: invoice.art,
          collectibles: invoice.collectibles,
          supplier: invoice.supplier ? {
            id: invoice.supplier.id,
            company_name: invoice.supplier.company_name,
            street: invoice.supplier.street,
            zip: invoice.supplier.zip,
            country: invoice.supplier.country,
            ico: invoice.supplier.ico,
            dic: invoice.supplier.dic,
            ic_dph: invoice.supplier.ic_dph
          } : nil,
          customer: invoice.customer ? {
            id: invoice.customer.id,
            company_name: invoice.customer.company_name,
            street: invoice.customer.street,
            zip: invoice.customer.zip,
            country: invoice.customer.country,
            ico: invoice.customer.ico,
            dic: invoice.customer.dic,
            ic_dph: invoice.customer.ic_dph
          } : nil,
          items: invoice.invoice_items.map { |item| {
            id: item.id,
            description: item.description,
            quantity: item.quantity,
            unit_price: item.unit_price,
            tax_rate: item.tax_rate,
            vat_amount: item.vat_amount,
            total_without_vat: item.total_without_vat,
            total_with_vat: item.total_with_vat
          }}
        }
      end
    end
  end
end