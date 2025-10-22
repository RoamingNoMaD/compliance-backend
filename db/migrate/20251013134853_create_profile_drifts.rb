class CreateProfileDrifts < ActiveRecord::Migration[8.0]
  def change
    create_table :profile_drifts, id: :uuid do |t|
      t.references :base_profile, null: false, type: :uuid
      t.references :target_profile, null: false, type: :uuid

      t.timestamps
    end

    add_foreign_key :profile_drifts, :profiles, column: :base_profile_id
    add_foreign_key :profile_drifts, :profiles, column: :target_profile_id
  end
end
