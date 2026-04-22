module Api
  module V1
    class AuthController < ApplicationController
      def signup
        user = User.new(user_params)

        if user.save
          token = encode_token(user.id)
          render json: {
            message: "Účet bol vytvorený úspešne",
            token: token,
            user: user_json(user)
          }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def login
        user = User.find_by(email: params[:email]&.downcase)

        if user&.authenticate(params[:password])
          token = encode_token(user.id)
          render json: {
            message: "Prihlásenie prebehlo úspešne",
            token: token,
            user: user_json(user)
          }
        else
          render json: { error: "Nesprávny e-mail alebo heslo" }, status: :unauthorized
        end
      end

      private

      def user_params
        params.require(:user).permit(:first_name, :last_name, :email, :password)
      end

      def user_json(user)
        {
          id: user.id,
          first_name: user.first_name,
          last_name: user.last_name,
          name: user.full_name,
          email: user.email
        }
      end
    end
  end
end