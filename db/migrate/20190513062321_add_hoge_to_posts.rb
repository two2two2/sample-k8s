class AddHogeToPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :hoge, :text
  end
end
