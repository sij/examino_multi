class ChangeCodTipoColumnsToIntegerInG1Details < ActiveRecord::Migration[8.0]
  def change
    change_column :g1_details, :cod_tipo_gioco, :integer, using: 'cod_tipo_gioco::integer'
    change_column :g1_details, :cod_tipo_conc, :integer, using: 'cod_tipo_conc::integer'
  end
end

