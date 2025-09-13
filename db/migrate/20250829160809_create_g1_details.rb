class CreateG1Details < ActiveRecord::Migration[8.0]
  def change
    create_table :g1_details do |t|
      t.integer :bet_point_id, null: false

      t.string  :csmf_cod
      t.date    :data
      t.integer :num_term
      t.string  :cod_tipo_gioco
      t.string  :cod_tipo_conc
      t.string  :des_gioco
      t.integer :num_emesso
      t.integer :impo_emesso
      t.integer :num_pagato
      t.integer :impo_pagato
      t.string  :tipologia

      t.timestamps
    end
  end
end

