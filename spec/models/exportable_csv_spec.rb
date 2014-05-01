require 'spec_helper'

describe Exportable::ExportableCSV do
  let(:filename) { 'abcd.csv' }
  let(:headers) { %w(One Two Three) }
  let(:mock_file) { Tempfile.new(filename) }

  subject { Exportable::ExportableCSV.new(filename, headers) }

  before do
    File.stub(:new).and_return(mock_file)
  end

  after { mock_file.delete }

  describe "#initialize" do
    it "sets @file to a new file with filename in 'wb:UTF-16' mode" do
      File.should_receive(:new).with(filename, "wb:UTF-16").and_return(mock_file)
      subject.instance_variable_get(:@file).should == mock_file
    end

    it "sets #num_rows to 0" do
      subject.num_rows.should == 0
    end

    it "sets @csv to a new CSV object with appropriate options" do
      CSV.should_receive(:new).with(
        mock_file,
        col_sep: "\t", quote_char: "\t", headers: headers, write_headers: true
      ).and_call_original

      csv = subject.instance_variable_get(:@csv)

      csv.should be_a(CSV)
    end
  end

  describe "#close" do
    it "calls File#close on @file" do
      mock_file.should_receive(:close)
      subject.close
    end
  end

  describe "<<" do
    it "adds the passed array to the CSV" do
      subject.instance_variable_get(:@csv).should_receive(:<<).
        with([1,2])
      subject << [1,2]
    end

    it "sets empty strings in the array to nil before adding" do
      subject.instance_variable_get(:@csv).should_receive(:<<).
        with(["a", nil, "b"])
      subject << ["a", "", "b"]
    end

    it "increments @num_rows by 1" do
      expect do
        subject << [1,2]
      end.to change(subject, :num_rows).by(1)
    end
  end
end
