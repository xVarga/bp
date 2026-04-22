module Api
  module V1
    class UsersController < ApplicationController
      before_action :authenticate_user!

      def me
        render json: {
          user: {
            id: @current_user.id,
            first_name: @current_user.first_name,
            last_name: @current_user.last_name,
            name: @current_user.full_name,
            email: @current_user.email
          }
        }
      end

      def update
        if params[:password].present?
          unless @current_user.authenticate(params[:current_password].to_s)
            return render json: { errors: ['Aktuálne heslo je nesprávne'] }, status: :unprocessable_entity
          end

          if params[:password] != params[:password_confirmation]
            return render json: { errors: ['Nové heslá sa nezhodujú'] }, status: :unprocessable_entity
          end
        end

        if @current_user.update(user_params)
          render json: {
            id: @current_user.id,
            first_name: @current_user.first_name,
            last_name: @current_user.last_name,
            name: @current_user.full_name,
            email: @current_user.email
          }
        else
          render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def user_params
        permitted = params.permit(:first_name, :last_name, :email)
        permitted[:password] = params[:password] if params[:password].present?
        permitted
      end
    end
  end
end