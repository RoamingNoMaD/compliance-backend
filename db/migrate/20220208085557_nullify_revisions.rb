class NullifyRevisions < ActiveRecord::Migration[6.1]
  def up
    Revision.find_by(name: 'datastreams')&.delete
  end

  def down
    #nop
  end
end
