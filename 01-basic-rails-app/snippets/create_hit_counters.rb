class CreateHitCounters < ActiveRecord::Migration[5.0]
  def change
    create_table :hit_counters do |t|
      t.integer :hits
      t.timestamps
    end
  end
end
