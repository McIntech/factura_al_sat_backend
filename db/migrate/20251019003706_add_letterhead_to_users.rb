class AddLetterheadToUsers < ActiveRecord::Migration[8.0]
  def change
    # No need to add a column because we'll use ActiveStorage
    # Just adding a comment for documentation purposes
    add_column :users, :letterhead_filename, :string, comment: "Filename of the uploaded letterhead template"
  end
end
