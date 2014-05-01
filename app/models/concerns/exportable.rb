require 'csv'

module Exportable
  module Exportable
    extend ActiveSupport::Concern

    # included class should have methods:
    # self.exportable_headers()
    # instance.exportable_row()
    # self.exportable or a named_scope of :exportable (optional) or be able to iterate over itself

    module ClassMethods

      def export_csv(file_name, col_sep = "\t")
        csv = ExportableCSV.new(file_name, exportable_headers, col_sep)

        collection = respond_to?(:exportable) ? exportable : self

        iterator = collection.respond_to?(:find_each) ? :find_each : :each

        collection.send(iterator) do |record|
          csv << record.exportable_row
        end

        csv.close

        csv.num_rows
      end

      #
      # Directly export from database to CSV without going through rails models.
      # Uses streaming of the columns/data.
      #
      def direct_export(file_name, sql = nil, col_sep = "\t")
        sql = self.select(column_names).to_sql if sql.blank?
        data = streaming_query(sql)
        return 0 if data.nil?

        write_to_csv(file_name, data.fields, data, col_sep)
      end

      def direct_export_in_batch(file_prefix, sql = nil, col_sep = "\t", batch_size = 10000, mode = "w:UTF-16")
        collection = respond_to?(:exportable) ? exportable : self
        sql = collection.select(column_names).to_sql if sql.blank?
        data = streaming_query(sql)
        return 0 if data.nil?

        num_batches = 0
        data.each_slice(batch_size) do |slice|
          num_batches += 1
          write_to_csv("#{file_prefix}.#{num_batches}", data.fields, slice, col_sep, mode )
        end
        num_batches
      end


      private

        def write_to_csv(file_name, headers, data, col_sep, mode = "w:UTF-16")
          num_rows = 0
          CSV.open(file_name, mode, {col_sep: col_sep, quote_char: col_sep}) do |csv|
            csv << headers # header row
            data.each do |row|
              csv << row.values
              num_rows += 1
            end
          end
          num_rows
        end

        def streaming_query(sql)
          db_config = ActiveRecord::Base.configurations[Rails.env].symbolize_keys.merge(cache_rows: false)
          db_client = Mysql2::Client.new( db_config )
          db_client.query(sql, stream: true)
        end

    end
  end
end
