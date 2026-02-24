module Admin
  class PasskeyAuthenticationController < ApplicationController
    include Authentication

    layout "admin_auth"

    def options
      options = WebAuthn::Credential.options_for_get
      session[:webauthn_authentication_challenge] = options.challenge

      render json: options
    end

    def verify
      webauthn_credential = WebAuthn::Credential.from_get(params[:credential])

      passkey = Passkey.find_by!(credential_id: webauthn_credential.id)

      webauthn_credential.verify(
        session[:webauthn_authentication_challenge],
        public_key: passkey.public_key,
        sign_count: passkey.sign_count
      )

      passkey.update!(sign_count: webauthn_credential.sign_count)
      passkey.touch_usage!
      session.delete(:webauthn_authentication_challenge)

      start_session(passkey.user, ip_address: request.remote_ip, user_agent: request.user_agent)

      render json: { redirect_url: admin_root_path }
    rescue WebAuthn::Error, ActiveRecord::RecordNotFound, TypeError, NoMethodError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end
