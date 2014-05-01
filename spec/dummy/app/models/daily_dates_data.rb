class DailyDatesData < ActiveRecord::Base
  include Exportable::Exportable

    # Exportable
  def self.exportable_headers
    column_names
  end

  def exportable_row
    DailyDatesData.exportable_headers.map{|col| attributes[col]}
  end
end
