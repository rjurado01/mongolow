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
    describe "presence_of" do
      context "when value is nil" do
        it "adds 'blank' error" do
          instance = MyModel.new
          instance.presence_of('name')
          expect(instance._errors['name']).to be_include('blank')
        end
      end

      context "when value is nil" do
        it "does not add error" do
          instance = MyModel.new(name: 'p1')
          instance.presence_of('name')
          expect(instance._errors['name']).to be_nil
        end
      end
    end

    describe "inclusion_of" do
      context "when value is not included" do
        it "adds 'inclusion' error" do
          instance = MyModel.new(name: 'p1')
          instance.inclusion_of('name', ['p2'])
          expect(instance._errors['name']).to be_include('inclusion')
        end
      end

      context "when value is nil" do
        it "does not add error" do
          instance = MyModel.new(name: 'p1')
          instance.inclusion_of('name', ['p1'])
          expect(instance._errors['name']).to be_nil
        end
      end
    end

    describe "uniquenes_of" do
      context "when value is not unique" do
        it "adds 'taken' error" do
          instance = MyModel.create(name: 'p1')
          instance = MyModel.new(name: 'p1')
          instance.uniquenes_of('name')
          expect(instance._errors['name']).to be_include('taken')
        end
      end

      context "when value is unique" do
        it "does not add error" do
          instance = MyModel.create(name: 'p1')
          instance = MyModel.new(name: 'p2')
          instance.uniquenes_of('name')
          expect(instance._errors['name']).to be_nil
        end
      end
    end

    describe "match_of" do
      context "when value is a string" do
        context "when value does not match" do
          it "adds 'taken' error" do
            instance = MyModel.new(name: 'p1')
            instance.match_of('name', 'p2')
            expect(instance._errors['name']).to be_include('match')
          end
        end

        context "when value matches" do
          it "does not add error" do
            instance = MyModel.new(name: 'p1')
            instance.match_of('name', 'p1')
            expect(instance._errors['name']).to be_nil
          end
        end
      end

      context "when value is regular expression" do
        context "when value does not match" do
          it "adds 'taken' error" do
            instance = MyModel.new(name: 'p1')
            instance.match_of('name', /a/)
            expect(instance._errors['name']).to be_include('match')
          end
        end

        context "when value matches" do
          it "does not add error" do
            instance = MyModel.new(name: 'p1')
            instance.match_of('name', /p\d/)
            expect(instance._errors['name']).to be_nil
          end
        end
      end
    end

    describe "add_error" do
      it "adds error to model" do
        instance = MyModel.new
        instance.send('add_error', 'name', 'blank')
        expect(instance._errors['name']).to eq(['blank'])
      end
    end
  end
end
