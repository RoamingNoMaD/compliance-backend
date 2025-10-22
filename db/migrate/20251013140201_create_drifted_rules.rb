class CreateDriftedRules < ActiveRecord::Migration[8.0]
  def change
    create_table :drifted_rules, id: :uuid do |t|
      t.references :profile_drift, null: false, foreign_key: true, type: :uuid
      t.references :rule, null: false, foreign_key: true, type: :uuid
      t.boolean :added

      t.timestamps
    end
  end
end
