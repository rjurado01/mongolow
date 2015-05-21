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

    describe "find_by_id" do
      it "return model instance" do
        id_1 = @session['my_model'].insert({name: 'name1'})
        id_2 = @session['my_model'].insert({name: 'name2'})

        MyModel.find_by_id('invalid').should == nil
        MyModel.find_by_id(id_2.to_s).name.should == 'name2'
        MyModel.find_by_id(id_2).name.should == 'name2'
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

    describe "destroy_by_id" do
      it "return model instance" do
        id_1 = @session['my_model'].insert({name: 'name1'})
        id_2 = @session['my_model'].insert({name: 'name2'})

        MyModel.destroy_by_id('invalid').should == false
        MyModel.destroy_by_id(id_2.to_s).should == true
        @session['my_model'].count.should == 1
        MyModel.destroy_by_id(id_1).should == true
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
        MyModel.first(name: 'name2')._id.should == id_2
        MyModel.first({name: 'name2'})._id.should == id_2
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

    describe "save_without_validation" do
      context "when document is new" do
        it "insert document in database" do
          instance = MyModel.new
          instance.name = 'name1'

          instance.should_receive('run_hook').with(:before_save)
          instance.should_receive('run_hook').with(:after_save)
          instance.save_without_validation

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

          instance.should_receive('run_hook').with(:before_save)
          instance.should_receive('run_hook').with(:after_save)
          instance.save_without_validation

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

          instance.should_receive('run_hook').with(:before_save)
          instance.should_receive('run_hook').with(:after_save)
          instance.save_without_validation

          @session['my_model'].find().count.should == 2
          @session['my_model'].find({'_id' => '123'}).first['name'].should == 'name1'
        end
      end
    end

    describe "save" do
      it "validate model" do
        instance = MyModel.new
        instance.should_receive('validate')
        instance.save
      end

      context "when document is valid" do
        it "save document" do
          instance = MyModel.new
          instance.should_receive('save_without_validation')
          instance.save
        end
      end

      context "when document is invalid" do
        it "don't save document" do
          instance = MyModel.new
          instance.stub(:validate).and_return(false)
          instance.should_not_receive('save_without_validation')
          instance.save
        end
      end
    end

    describe "save!" do
      context "when document is invalid" do
        it "throw an exception" do
          instance = MyModel.new
          instance._errors = {name: 'blank'}
          instance.stub(:validate).and_return(false)
          expect {
            instance.save!
          }.to raise_error(Mongolow::Exceptions::Validations) do |e|
            expect(e.message).to eq instance._errors.to_s
          end
        end
      end

      context "when document is valid" do
        it "save document" do
          instance = MyModel.new
          instance.should_receive('save_without_validation')
          instance.save!
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

    describe "id" do
      it "return _id field in string format" do
        instance = MyModel.new
        instance.save
        instance.id.should == instance._id.to_s
      end
    end

    describe "validate" do
      it "return true when model is valid" do
        instance = MyModel.new
        instance.should_receive('run_hook').with(:validate)
        instance.validate.should == true
      end

      it "return false when model is invalid" do
        class MyModel2
          include Mongolow::Model

          validate do
            self._errors = {'intance' => 'invalid'}
          end
        end

        instance = MyModel2.new
        instance.should_receive('run_hook').with(:validate).and_call_original
        instance.validate.should == false
      end
    end

    describe "errors?" do
      it "return if model has errors" do
        instance = MyModel.new
        instance.errors?.should == false
        instance._errors = {}
        instance.errors?.should == false
        instance._errors = {name: 'invalid'}
        instance.errors?.should == true
      end
    end

    describe "template" do
      it "return all fields" do
        class MyModel
          include Mongolow::Model

          field :name
          field :email

          def custom_template(options)
            return {
              'custom_name' => self.name,
              'custom_email' => self.email,
              'role' => options[:role]
            }
          end
        end

        instance = MyModel.new({name: 'm1', email: 'm1@email.com'})
        instance.save

        instance.template.should == {
          'id' => instance.id,
          'name' => 'm1',
          'email' => 'm1@email.com'
        }
        instance.template('custom_template', {role: 'admin'}).should == {
          'custom_name' => 'm1',
          'custom_email' => 'm1@email.com',
          'role' => 'admin'
        }
      end
    end
  end
end
