require 'spec_helper'

describe "MyModel" do
  before :all do
    class MyModel
      include Mongolow::Model
    end
  end

  describe "Functionality" do
    context "when create new instance" do
      it "everything works fine" do
        instance = MyModel.new
        instance.should_not == nil

        MyModel.send('field', 'name')
        instance = MyModel.new({_id: '123', name: 'name1'})
        instance.should_not == nil
        instance._id.should == '123'
        instance.name.should == 'name1'
      end
    end
  end

  describe "Class Methods" do
    before :all do
      @session = MongoClient.new( '127.0.0.1', 27017 ).db( 'mongolow_test' )
      Mongolow::Driver.initialize('127.0.0.1', 27017, 'mongolow_test')
      MyModel.send('field', 'name')
    end

    before do
      @session['my_model'].remove
    end

    describe "find" do
      it "return mongodb query" do
        id_1 = @session['my_model'].insert({name: 'name1'})

        query = MyModel.find({'_id' => id_1})
        query.class.should == Mongolow::Cursor
        query.mongo_cursor.selector.should == {'_id' => id_1}
      end
    end

    describe "destroy_all" do
      it "remove all documents" do
        id_1 = @session['my_model'].insert({name: 'name1'})
        id_2 = @session['my_model'].insert({name: 'name2'})
        MyModel.destroy_all
        @session['my_model'].count.should == 0
      end
    end

    describe "count" do
      it "return number of models" do
        id_1 = @session['my_model'].insert({name: 'name1'})
        id_2 = @session['my_model'].insert({name: 'name2'})
        MyModel.count.should == 2
      end
    end

    describe "first" do
      it "return first model" do
        id_1 = @session['my_model'].insert({name: 'name1'})
        id_2 = @session['my_model'].insert({name: 'name2'})
        MyModel.first._id.should == id_1
        MyModel.first.class.should == MyModel
      end
    end
  end

  describe "Instance Methods" do
    before :all do
      @session = MongoClient.new( '127.0.0.1', 27017 ).db( 'mongolow_test' )
      Mongolow::Driver.initialize('127.0.0.1', 27017, 'mongolow_test')
      MyModel.send('field', 'name')
    end

    before do
      @session['my_model'].remove
    end

    describe "save" do
      context "when document is new" do
        it "insert document in database" do
          instance = MyModel.new
          instance.name = 'name1'

          instance.should_receive('before_save')
          instance.should_receive('after_save')
          instance.save

          instance._id.should_not == nil
          instance.name.should == 'name1'
          @session['my_model'].find().count.should == 1
        end
      end

      context "when document already exists in database" do
        it "update document in database" do
          id_1 = @session['my_model'].insert({name: 'name1'})
          instance = MyModel.find({_id: id_1}).first
          instance.name = 'name1'

          instance.should_receive('before_save')
          instance.should_receive('after_save')
          instance.save

          instance._id.should_not == nil
          instance.name.should == 'name1'
          @session['my_model'].find().count.should == 1
        end
      end

      context "when change document _id" do
        it "insert new document in database" do
          id_1 = @session['my_model'].insert({name: 'name1'})
          instance = MyModel.find({_id: id_1}).first
          instance._id = '123'

          instance.should_receive('before_save')
          instance.should_receive('after_save')
          instance.save

          @session['my_model'].find().count.should == 2
          @session['my_model'].find({'_id' => '123'}).first['name'].should == 'name1'
        end
      end
    end

    describe "set" do
      it "update field" do
        id_1 = @session['my_model'].insert({name: 'name1'})
        instance = MyModel.find({_id: id_1}).first
        instance.set('name', 'name2')

        @session['my_model'].find({'_id' => id_1}).first['name'].should == 'name2'
      end
    end

    describe "delete" do
      it "delete field from database" do
        id_1 = @session['my_model'].insert({name: 'name1'})
        instance = MyModel.find({_id: id_1}).first
        instance.destroy

        @session['my_model'].find().count.should == 0
      end
    end
  end
end