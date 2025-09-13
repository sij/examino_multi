class ApplicationController < ActionController::Base
  include Authentication
  before_action :set_locale
  around_action :switch_tertiary_shard

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  rescue_from CanCan::AccessDenied do |exception|
    if current_user.nil?
      # Se non autenticato, manda sempre alla pagina di login
      redirect_to new_session_path, alert: "Devi autenticarti."
    else
      # Se autenticato, torna alla root (o dove preferisci)
      redirect_to root_url, alert: exception.message
    end
  end

  helper_method :current_user
  helper_method :codice_punto, :comune_punto, :id_punto, :cod_punto_by_id, :comune_punto_by_id

  def cod_punto_by_id(id)
    Point.find(id).code.strip
  end

  def comune_punto_by_id(id)
    Point.find(id)&.municipality&.comune
  end

  def id_punto
    if not current_user
      return 'nessun punto'
    else
      Point.find(current_user.bet_point_id).bet_point_id
    end
  end

  def codice_punto
    if not current_user
      return 'nessun punto'
    else
      Point.find(current_user.bet_point_id).code.strip
    end
  end

  def comune_punto
    if current_user.nil?
      return ''
    else
      Point.find(current_user.bet_point_id).municipality.comune.strip
    end
  end

  def current_user
    if session[:user_id]
      @current_user ||= User.find_by(id: session[:user_id])
    end
  end

  private

  def set_locale
    I18n.locale = :it
  end

  # nuovo metodo per switch del database
  def switch_tertiary_shard
    return yield unless current_user

    shard = TERTIARY_DATABASES[current_user.owner_id]
    
    return yield unless shard

    TertiaryRecord.connected_to(role: :writing, shard: shard) do
      yield
    end
  end
end
