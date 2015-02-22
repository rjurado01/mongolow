require 'spec_helper'

describe "Mongolow::Driver" do
  context "when call session method" do
    it "return session instance" do
      session = Mongolow::Driver.initialize('127.0.0.1', 27017, 'mongolow_test')
      Mongolow::Driver.session.should == session
    end
  end
end
