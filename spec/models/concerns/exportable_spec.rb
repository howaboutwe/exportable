require 'spec_helper'

describe Exportable::Exportable do

  let!(:filename) { "export_test.csv" }
  let(:dummy_class)  { Class.new { include Exportable::Exportable } }
  let(:dummy_instance) { dummy_class.new }

  describe "export_csv" do

    before do
      dummy_class.stub(:exportable) { [dummy_instance] }
    end

    after do
      FileUtils.rm_f(filename)
    end

    it "generates a CSV with the headers from the exportable_headers method" do
      dummy_class.stub(:exportable_headers) { ["header1", "header2"] }

      dummy_instance.stub(exportable_row: ["foo", "bar"])

      dummy_class.export_csv(filename)

      exported_data = File.open(filename, "r:UTF-16:UTF-8").readlines
      exported_data[0].chomp.should == "header1\theader2"
    end

    it "exports row data from the exportable_row method" do
      dummy_instance.stub(title: "offer_1")

      dummy_class.stub(:exportable_headers) { ["title"] }
      dummy_class.any_instance.stub(:exportable_row) { ["some_title"] }

      dummy_class.export_csv(filename)

      exported_data = File.open(filename, "r:UTF-16:UTF-8").readlines
      exported_data.size.should == 2
      exported_data[1].should == "some_title\n"
    end

    it "handles foreign characters" do
      dummy_class.stub(:exportable_headers) { ["login"] }
      dummy_class.any_instance.stub(:exportable_row) { ["forëign"] }

      dummy_class.export_csv(filename)

      exported_data = File.readlines(filename, encoding:"UTF-16:UTF-8")
      exported_data.size.should == 2
      exported_data[1].should == "forëign\n"
    end

    it "handles double- and single-quotes in fields properly" do
      dummy_instance.stub(title: "offer_1")
      dummy_class.stub(:exportable_headers) { ["title"] }
      dummy_class.any_instance.stub(:exportable_row) { ['some "ti\'tle"'] }

      dummy_class.export_csv(filename)

      exported_data = File.open(filename, "r:UTF-16:UTF-8").readlines
      exported_data[1].should == "some \"ti'tle\"\n"
    end

    it "uses the specified column separator" do
      dummy_instance.stub(title: "offer_1")
      dummy_class.stub(:exportable_headers) { ["header1", "header2"] }
      dummy_class.any_instance.stub(:exportable_row) { ['some data', 'for you'] }

      dummy_class.export_csv(filename, "|")

      exported_data = File.open(filename, "r:UTF-16:UTF-8").readlines
      exported_data[0].chomp.should == "header1|header2"
    end

    it "returns the number of rows exported" do
      dummy_class.stub(exportable: [])
      dummy_class.stub(:exportable_headers) { ["header1", "header2"] }

      dummy_class.export_csv(filename, "|").should == 0

      dummy_class.stub(exportable: [dummy_instance])
      dummy_class.any_instance.stub(:exportable_row) { ['some data', 'for you'] }
      dummy_class.export_csv(filename, "|").should == 1
    end

    it "should replace empty strings with nil so they are not quoted" do
      dummy_instance.stub(title: "offer_1")
      dummy_class.stub(:exportable_headers) { ["title"] }
      dummy_class.any_instance.stub(:exportable_row) { [""] }

      dummy_class.export_csv(filename)

      exported_data = File.open(filename, "r:UTF-16:UTF-8").readlines
      exported_data[1].should == "\n"
    end
  end

  describe "direct_export" do
    context "when its a single dump" do
      after do
        FileUtils.rm_f(filename)
      end

      it "returns 0 if no data is present" do
        DailyDatesData.direct_export(filename).should == 0
      end

      it "creates a CSV with headers that match all model columns" do
        FactoryGirl.create(:daily_dates_data)
        DailyDatesData.direct_export(filename)

        exported_data = File.readlines(filename, encoding:"UTF-16:UTF-8")
        exported_data[0].chomp.should == DailyDatesData.column_names.join("\t")
      end

      it "returns the # of rows exported" do
        FactoryGirl.create(:daily_dates_data)
        DailyDatesData.direct_export(filename).should == 1
      end

      it "dumps table data to the file" do
        FactoryGirl.create(:daily_dates_data)

        daily_date = DailyDatesData.first
        daily_date.update_attribute(:site, "my_custom_site")
        DailyDatesData.direct_export(filename)

        exported_data = File.readlines(filename, encoding:"UTF-16:UTF-8")
        exported_data[1].split("\t")[3].should == "my_custom_site"
      end

      it "uses custom SQL when given" do
        DailyDatesData.should_receive(:streaming_query).with("select 1")
        DailyDatesData.direct_export(filename, "select 1")
      end
    end

    context "when its a batch dump" do
      before do
        (1..2).each { FactoryGirl.create(:daily_dates_data) }
      end

      after do
        (1..2).each {|i| FileUtils.rm_r("#{filename}.#{i}") }
      end

      it "creates multiple files" do
        DailyDatesData.direct_export_in_batch(filename, nil, "\t", 1)
        File.exists?("#{filename}.1").should be_true
        File.exists?("#{filename}.2").should be_true
      end

      it "dumps table data to multiple files" do
        daily_dates = DailyDatesData.all
        (0..1).each {|i| daily_dates[i].update_attribute(:site, "site #{i}")}
        DailyDatesData.direct_export_in_batch(filename, nil, "\t", 1)

        (1..2).each do |i|
          exported_data = File.readlines("#{filename}.#{i}", encoding: "UTF-16:UTF-8")
          exported_data[1].split("\t")[3].should == "site #{i-1}"
        end
      end

      it "returns the # of batches exported" do
        DailyDatesData.direct_export_in_batch(filename, nil, "\t", 1).should == 2
      end
    end
  end
end
