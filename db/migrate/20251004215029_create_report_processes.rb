class CreateReportProcesses < ActiveRecord::Migration[7.2]
  def change
    create_table :report_processes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "queued"
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.text :error_message
      t.integer :progress, default: 0
      t.string :process_id, null: false, index: { unique: true }

      t.timestamps
    end
  end
end
