module Admin
  class PasskeysController < BaseController
    def index
      @passkeys = current_user.passkeys.order(created_at: :desc)
    end

    def registration_options
      options = WebAuthn::Credential.options_for_create(
        user: {
          id: WebAuthn.generate_user_id,
          name: current_user.email,
          display_name: current_user.display_name
        },
        exclude: current_user.passkeys.pluck(:credential_id)
      )
      session[:webauthn_registration_challenge] = options.challenge

      render json: options
    end

    def create
      credential_data = JSON.parse(params[:credential])
      webauthn_credential = WebAuthn::Credential.from_create(credential_data)

      webauthn_credential.verify(session[:webauthn_registration_challenge])

      current_user.passkeys.create!(
        credential_id: webauthn_credential.id,
        public_key: webauthn_credential.public_key,
        name: params[:name].presence || "Passkey",
        sign_count: webauthn_credential.sign_count
      )

      session.delete(:webauthn_registration_challenge)

      redirect_to admin_passkeys_path, notice: t("flash.admin.passkeys.registered")
    rescue WebAuthn::Error, JSON::ParserError => e
      redirect_to admin_passkeys_path, alert: e.message
    end

    def destroy
      passkey = current_user.passkeys.find(params[:id])
      passkey.destroy

      redirect_to admin_passkeys_path, notice: t("flash.admin.passkeys.removed")
    end
  end
end
