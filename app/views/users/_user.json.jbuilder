json.extract! user, :id, :name, :email_address, :info, :role_id, :enabled, :bet_point_id, :created_at, :updated_at
json.url user_url(user, format: :json)
