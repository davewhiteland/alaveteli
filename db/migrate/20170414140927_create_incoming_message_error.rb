# -*- encoding : utf-8 -*-
class CreateIncomingMessageError < ActiveRecord::Migration
  def change
    create_table :incoming_message_errors do |t|
      t.timestamps null: false
      t.text :unique_id, null: false
      t.datetime :retry_at
    end

    add_index :incoming_message_errors, :unique_id
  end
end
