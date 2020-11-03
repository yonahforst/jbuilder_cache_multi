ActiveRecord::Schema.define do
  self.verbose = false

  create_table :posts, :force => true do |t|
    t.string :title
    t.string :body
    t.integer :author_id

    t.timestamps
  end

  create_table :authors, :force => true do |t|
    t.string :name
    t.integer :age

    t.timestamps
  end

end
