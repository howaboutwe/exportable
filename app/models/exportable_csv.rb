module Exportable
  class ExportableCSV
    attr_reader :num_rows

    def initialize(filename, headers, col_sep = "\t", &block)
      @file = File.new(filename, "wb:UTF-16")
      @num_rows = 0
      @csv = CSV.new(@file, col_sep: col_sep, quote_char: col_sep, headers: headers, write_headers: true)

      if block_given?
        yield(self)
        close
      end
      self
    end

    def close
      @file.close
    end

    def <<(arr)
      @csv << arr.map(&:presence) # presence needed to avoid CSV quoting empty strings
      @num_rows += 1
    end
  end
end
