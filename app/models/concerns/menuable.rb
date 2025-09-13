module Menuable
  extend ActiveSupport::Concern

  MENU_CONFIG = {
    admin: [
      { id: 0, label: "Admin", color: "purple", submenu: :admin },
      { id: 3, label: "Punti Gioco", color: "teal", submenu: :punti },
      { id: 2, label: "Terminali", color: "yellow", submenu: :terminali },
      { id: 4, label: "Report Gioco", color: "red", submenu: :report_gioco}
    ],
    concessionario: [
      { id: 3, label: "Punti Gioco", color: "teal", submenu: :punti },
      { id: 2, label: "Terminali", color: "yellow", submenu: :terminali },
      { id: 4, label: "Report Gioco", color: "red", submenu: :report_gioco}
    ]
  }

  def available_menu_items
    if admin?
      MENU_CONFIG[:admin]
    elsif concessionario?
      MENU_CONFIG[:concessionario]
    else
      []
    end
  end
end
