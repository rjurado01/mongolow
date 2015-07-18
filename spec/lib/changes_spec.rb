require 'spec_helper'

describe Mongolow::Changes do
  before :all do
    Mongo::Logger.logger = Logger.new('/dev/null')
    Mongolow::Driver.initialize('127.0.0.1', 27017, 'mongolow_test')

    class MyModel
      include Mongolow::Model
      field :name
    end
  end

  describe "Methods" do
    describe "set_old_values" do
      it "creates a copy of actual fields values" do
        instance = MyModel.new({name: 'p1'})
        instance.send('set_old_values')
        expect(instance._old_values).to eq({'name' => 'p1'})
      end
    end

    describe "changed?" do
      context "when field has changed" do
        it "returns true" do
          instance = MyModel.new({name: 'p1'})
          expect(instance.changed?('name')).to eq(true)
        end
      end

      context "when field has not changed" do
        it "returns false" do
          instance = MyModel.new({name: 'p1'})
          instance.save
          expect(instance.changed?('name')).to eq(false) 
        end
      end
    end

    describe "changed" do
      context "when there isn't changes" do
        it "returns empty array" do
          instance = MyModel.new({name: 'p1'})
          instance.save
          expect(instance.changed).to eq([])
        end
      end

      context "when there is changes" do
        it "returns changed fields array" do
          instance = MyModel.new({name: 'p1'})
          expect(instance.changed).to eq(['name'])
        end
      end
    end
  end
end
