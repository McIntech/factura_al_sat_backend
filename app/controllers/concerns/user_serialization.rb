# app/controllers/concerns/user_serialization.rb
module UserSerialization
  extend ActiveSupport::Concern

  def serialize_user(user)
    user_data = {
      id: user.id,
      email: user.email,
      name: user.full_name,
      admin: user.admin,
      account_id: user.account_id,
      first_name: user.first_name,
      last_name: user.last_name,
      company_name: user.company_name,
    }
    
    # Añadir información de la hoja membretada si existe
    if user.letterhead.attached?
      user_data[:letterhead] = {
        filename: user.letterhead.filename.to_s,
        url: Rails.application.routes.url_helpers.rails_blob_path(user.letterhead, only_path: true)
      }
      user_data[:letterhead_filename] = user.letterhead.filename.to_s
    end
    
    user_data
  end
end