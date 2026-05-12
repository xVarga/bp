module Api
    module V1
        class CompaniesController < ApplicationController
            before_action :authenticate_user!

            # GET /api/v1/companies
            def index
                companies = @current_user.companies.where(archived: false)
                render json: companies.map { |c| company_json(c) }
            end

            # GET /api/v1/companies/:id
            def show
                company = @current_user.companies.find(params[:id])
                render json: company_json(company)
            rescue ActiveRecord::RecordNotFound
                render json: { error: 'Firma nenájdená' }, status: :not_found
            end

            # POST /api/v1/companies
            def create
                company = @current_user.companies.new(company_params)
                if company.save
                render json: company_json(company), status: :created
                else
                render json: { errors: company.errors.full_messages }, status: :unprocessable_entity
                end
            end

            # PUT /api/v1/companies/:id
            def update
                old_company = @current_user.companies.find(params[:id])
                old_company.update(archived: true)
                new_company = @current_user.companies.create(company_params)
                if new_company.persisted?
                    render json: company_json(new_company), status: :created
                else
                    render json: { errors: new_company.errors.full_messages }, status: :unprocessable_entity
                end
            end

            private

            def company_params
                params.require(:company).permit(
                :company_name, :street, :zip, :city, :country,
                :ico, :dic, :ic_dph
                )
            end

            def company_json(company)
                {
                id: company.id,
                company_name: company.company_name,
                street: company.street,
                zip: company.zip,
                city: company.city,
                country: company.country,
                ico: company.ico,
                dic: company.dic,
                ic_dph: company.ic_dph
                }
            end
        end
    end
end