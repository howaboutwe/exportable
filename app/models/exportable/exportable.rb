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
        collection = respond_to?(:exportable) ? exportable : self

        write_to_csv(file_name, collection, col_sep) {|rec| rec.exportable_row }
      end

      #
      # Directly export from database to CSV without going through rails models (too much).
      # Uses streaming of the columns/data.
      #
      def direct_export(file_name, sql = nil, col_sep = "\t")
        sql = self.select(column_names).to_sql if sql.blank?
        data = streaming_query(sql)
        return 0 if data.nil?

        write_to_csv(file_name, data, col_sep) {|rec| rec.values }
      end

      def direct_export_in_batch(file_prefix, sql = nil, col_sep = "\t", batch_size = 10000, mode = "w:UTF-16")
        collection = respond_to?(:exportable) ? exportable : self
        sql = collection.select(column_names).to_sql if sql.blank?
        data = streaming_query(sql)
        return 0 if data.nil?

        num_batches = 0
        data.each_slice(batch_size) do |slice|
          num_batches += 1
          write_to_csv("#{file_prefix}.#{num_batches}", slice, col_sep, mode ) {|rec| rec.values }
        end
        num_batches
      end


      private
        def write_to_csv(file_name, data, col_sep, mode = "w:UTF-16", &block)
          export = ExportableCSV.new(file_name, exportable_headers, col_sep, mode) do |csv|
            iterator = data.respond_to?(:find_each) ? :find_each : :each
            data.send(iterator) do |rec|
              csv << yield(rec)
            end
          end
          export.num_rows
        end

        def streaming_query(sql)
          db_config = ActiveRecord::Base.configurations[Rails.env].symbolize_keys.merge(cache_rows: false)
          db_client = Mysql2::Client.new( db_config )
          db_client.query(sql, stream: true)
        end

    end
  end
end
