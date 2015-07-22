require 'spec_helper'

describe "Mongolow::Driver" do
  describe "client" do
    it "returns client instance" do
      client = Mongolow::Driver.initialize('127.0.0.1', 27017, 'mongolow_test')
      expect(Mongolow::Driver.client).to eq(client)
    end
  end

  describe "drop_database" do
    it "drops database" do
      client = Mongolow::Driver.initialize('127.0.0.1', 27017, 'mongolow_test')
      client['my_model'].insert_one({name: 'name1'})
      Mongolow::Driver.drop_database
      expect(client.database.collection_names).to eq([])
    end
  end

  describe "initialize_from_file" do
    it "loads config from yml file" do
      client = Mongolow::Driver.initialize_from_file('spec/config/mongolow.yml')
      expect(client.database.name).to eq('mongolow_test')
    end
  end
end
