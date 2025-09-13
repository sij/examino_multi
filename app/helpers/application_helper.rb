module ApplicationHelper
    def eu_date(date)
    date.strftime("%d/%m/%Y") if date.present?
    end    

    def eu_number(number)
    numero = number.to_f / 100
    number_to_currency(numero, unit: "", separator: ",", delimiter: ".")
    end



  def tipologia_color_class(tip)
    {
      "operatore"    => "text-blue-600 bg-blue-100",
      "SelfService"  => "text-green-700 bg-green-100",
      "SelfAdvance"  => "text-yellow-700 bg-yellow-100"
    }[tip] || "text-gray-700 bg-gray-50"
  end

  def gioco_color_class(gioco)
    {
      "Totale"    => "text-gray-700 bg-gray-100",
      "SPORT"     => "text-white bg-red-600",
      "VIRTUALI"  => "text-white bg-blue-600"
    }[gioco] || "text-gray-500 bg-gray-50"
  end


end
