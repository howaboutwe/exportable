class CreateDailyDatesDataTable < ActiveRecord::Migration
  def up
    create_table :daily_dates_data do |t|
      t.string :email, null: false, limit: 128
      t.integer :userID, null: false
      t.string :site, null: false, limit: 50
      t.string :site_url, null: false
      t.string :site_name, null: false
      t.string :single_access_token, null: true
      t.string :recipient_city, null: true
      t.string :recipient_login, null: false
      t.string :image_url, null: false, limit: 512
      t.string :date_text, null: false, limit: 250
      t.string :login, null: false, limit: 50
      t.integer :age, null: false
      t.string :gender, null: false, limit: 50
      t.string :orientation, null: false
      t.string :city, null: true, limit: 50
      t.string :state, null: true, limit: 50
      t.string :imp_url, null: true, limit: 2048
    end
  end

  def down
    drop_table :daily_dates_data
  end
end
