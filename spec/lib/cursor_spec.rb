require 'spec_helper'

describe "Mongolow::Cursor" do
  before :all do
    class Person
      attr_accessor :name

      def initialize(hash)
        @name = hash['name']
      end
    end
  end

  describe "Functionality" do
    context "when create new instance" do
      it "everything works fine" do
        instance = Mongolow::Cursor.new(Person, [])
        instance.should_not == nil
      end
    end
  end

  describe "Instace Methods" do
    before do
      @instance = Mongolow::Cursor.new(Person, [{'name' => 'name1'}, {'name' => 'name2'}])
    end

    context "first" do
      it "return first model" do
        model = @instance.first
        model.class.should == Person
        model.name.should == 'name1'
      end
    end

    context "all" do
      it "return all models" do
        models = @instance.all
        models.size.should == 2
        models[0].class.should == Person
        models[0].name.should == 'name1'
        models[1].class.should == Person
        models[1].name.should == 'name2'
      end
    end

    context "count" do
      it "return number of models" do
        @instance.count.should == 2
      end
    end

    context "limit" do
      it "limited query documents" do
        @instance.mongo_cursor.stub(:limit).and_return(true)
        @instance.mongo_cursor.should_receive(:limit)
        @instance.limit(1).class.should == Mongolow::Cursor
      end
    end

    context "skip" do
      it "skip n documents" do
        @instance.mongo_cursor.stub(:skip).and_return(true)
        @instance.mongo_cursor.should_receive(:skip)
        @instance.skip(1).class.should == Mongolow::Cursor
      end
    end
  end
end
