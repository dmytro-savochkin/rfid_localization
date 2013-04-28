class CreateAlgorithms < ActiveRecord::Migration
  def change
    create_table :algorithm do |t|
      t.text :name
      t.text :description

      t.timestamps
    end
  end
end
