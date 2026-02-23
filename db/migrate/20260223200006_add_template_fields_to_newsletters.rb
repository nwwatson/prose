class AddTemplateFieldsToNewsletters < ActiveRecord::Migration[8.1]
  def change
    change_table :newsletters do |t|
      t.string :template
      t.string :accent_color
      t.string :preheader_text
    end
  end
end
