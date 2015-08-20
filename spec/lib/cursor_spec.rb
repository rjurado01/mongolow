require 'spec_helper'

describe Mongolow::Cursor do
  before :all do
    class Person
      attr_accessor :name

      def initialize(hash)
        @name = hash['name']
      end
    end
  end

  before do
    allow_any_instance_of(Person).to receive(:set_old_values).and_return(true)
  end

  describe "Functionality" do
    context "when create new instance" do
      it "everything works fine" do
        expect(Mongolow::Cursor.new(Person, [])).not_to eq(nil)
      end
    end
  end

  describe "Instace Methods" do
    before do
      @instance = Mongolow::Cursor.new(Person, [{'name' => 'name1'}, {'name' => 'name2'}])
    end

    describe "first" do
      it "return first model" do
        model = @instance.first
        expect(model.class).to eq(Person)
        expect(model.name).to eq('name1')
      end

      it "call set_old_values" do
        expect(@instance.first).to have_received(:set_old_values)
      end
    end

    describe "all" do
      it "return all models" do
        models = @instance.all
        expect(models.size).to eq(2)
        expect(models[0].class).to eq(Person)
        expect(models[0].name).to eq('name1')
        expect(models[1].class).to eq(Person)
        expect(models[1].name).to eq('name2')
      end

      it "call set_old_values" do
        @instance.all.each do |model|
          expect(model).to have_received(:set_old_values)
        end
      end
    end

    describe "count" do
      it "return number of models" do
        expect(@instance.count).to eq(2)
      end
    end

    describe "limit" do
      it "limited query documents" do
        cursor = @instance.mongo_cursor
        allow(cursor).to receive(:limit).and_return("limited_cursor")
        expect(@instance.limit(1).class).to eq(Mongolow::Cursor)
        expect(cursor).to have_received(:limit)
        expect(@instance.mongo_cursor).to eq("limited_cursor")
      end
    end

    describe "skip" do
      it "skip n documents" do
        cursor = @instance.mongo_cursor
        allow(cursor).to receive(:skip).and_return("skiped_cursor")
        expect(@instance.skip(1).class).to eq(Mongolow::Cursor)
        expect(cursor).to have_received(:skip).with(1)
        expect(@instance.mongo_cursor).to eq("skiped_cursor")
      end
    end

    describe "sort" do
      it "sort query" do
        cursor = @instance.mongo_cursor
        allow(cursor).to receive(:sort).and_return("sorted_cursor")
        expect(@instance.sort(1).class).to eq(Mongolow::Cursor)
        expect(cursor).to have_received(:sort).with(1)
        expect(@instance.mongo_cursor).to eq("sorted_cursor")
      end
    end

    describe "find" do
      it "add options to mongo cursor selector" do
        class MongoCursor
          attr_accessor :selector
        end

        mongo_cursor = MongoCursor.new
        mongo_cursor.selector = {one: 1}
        cursor = Mongolow::Cursor.new(Person, mongo_cursor)
        cursor.find({two: 2})
        expect(cursor.mongo_cursor.selector).to eq({one: 1, two: 2})
      end
    end
  end
end
