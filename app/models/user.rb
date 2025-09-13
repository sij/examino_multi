class User < ApplicationRecord
  include Menuable # sistema menu

  has_secure_password
  belongs_to :role
  belongs_to :owner

  # belongs_to :point # TODO: con questa attivata non funziona cambia punto
	
  has_many :sessions, dependent: :destroy

  normalizes :name, with: ->(n) { n.strip } 

  validates :name, presence: true, uniqueness: true
  VALID_EMAIL_REGEX = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/
  validates :email_address, presence: true, format: { with: VALID_EMAIL_REGEX, message: "must be a valid email address" }

  # --- AGGIUNGI QUESTA CALLBACK ---
  before_validation :set_default_password, on: :create

  def bet_point_code
    Point.find_by(id: self.bet_point_id)&.code
  end

  def admin?
    role&.name&.downcase == "admin"
  end

  def concessionario?
    role&.name&.downcase == "concessionario"
  end

  private

  def set_default_password
    if self.password.blank?
      self.password = "sunbetpw2004"  # Cambia qui la password di default!
      self.password_confirmation = "sunbetpw2004"
    end
  end
end