class CreateTailoringMigrations < ActiveRecord::Migration[8.0]
  def change
    create_view :tailoring_migrations
  end
end
