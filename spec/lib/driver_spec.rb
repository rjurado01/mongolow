require 'spec_helper'

describe "Mongolow::Driver" do
  describe "session" do
    it "returns session instance" do
      session = Mongolow::Driver.initialize('127.0.0.1', 27017, 'mongolow_test')
      expect(Mongolow::Driver.session).to eq(session)
    end
  end

  describe "drop_database" do
    it "drops database" do
      session = Mongolow::Driver.initialize('127.0.0.1', 27017, 'mongolow_test')
      session['my_model'].insert({name: 'name1'})
      Mongolow::Driver.drop_database
      expect(session.collection_names).to eq([])
    end
  end
end
