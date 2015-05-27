require 'spec_helper'

describe Mongolow::Model do
  before :all do
    class MyModel
      include Mongolow::Model
    end
  end

  describe "Functionality" do
    context "when create new instance" do
      it "everything works fine" do
        instance = MyModel.new
        expect(instance).not_to eq(nil)

        MyModel.send('field', 'name')
        instance = MyModel.new({_id: '123', name: 'name1'})
        expect(instance).not_to eq(nil)
        expect(instance._id).to eq('123')
        expect(instance.name).to eq('name1')
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
        expect(query.class).to eq(Mongolow::Cursor)
        expect(query.mongo_cursor.selector).to eq({'_id' => id_1})
      end
    end

    describe "find_by_id" do
      it "return model instance" do
        id_1 = @session['my_model'].insert({name: 'name1'})
        id_2 = @session['my_model'].insert({name: 'name2'})

        expect(MyModel.find_by_id('invalid')).to eq(nil)
        expect(MyModel.find_by_id(id_2.to_s).name).to eq('name2')
        expect(MyModel.find_by_id(id_2).name).to eq('name2')
      end
    end

    describe "destroy_all" do
      it "remove all documents" do
        id_1 = @session['my_model'].insert({name: 'name1'})
        id_2 = @session['my_model'].insert({name: 'name2'})
        MyModel.destroy_all
        expect(@session['my_model'].count).to eq(0)
      end
    end

    describe "destroy_by_id" do
      it "return model instance" do
        id_1 = @session['my_model'].insert({name: 'name1'})
        id_2 = @session['my_model'].insert({name: 'name2'})

        expect(MyModel.destroy_by_id('invalid')).to eq(false)
        expect(MyModel.destroy_by_id(id_2.to_s)).to eq(true)
        expect(@session['my_model'].count).to eq(1)
        expect(MyModel.destroy_by_id(id_1)).to eq(true)
        expect(@session['my_model'].count).to eq(0)
      end
    end

    describe "count" do
      it "return number of models" do
        id_1 = @session['my_model'].insert({name: 'name1'})
        id_2 = @session['my_model'].insert({name: 'name2'})
        expect(MyModel.count).to eq(2)
      end
    end

    describe "first" do
      it "return first model" do
        id_1 = @session['my_model'].insert({name: 'name1'})
        id_2 = @session['my_model'].insert({name: 'name2'})
        expect(MyModel.first._id).to eq(id_1)
        expect(MyModel.first.class).to eq(MyModel)
        expect(MyModel.first(name: 'name2')._id).to eq(id_2)
        expect(MyModel.first({name: 'name2'})._id).to eq(id_2)
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
          allow(instance).to receive('run_hook').and_return(true)
          instance.save_without_validation

          expect(instance).to have_received('run_hook').with(:before_save)
          expect(instance).to have_received('run_hook').with(:after_save)
          expect(instance._id).not_to eq(nil)
          expect(instance.name).to eq('name1')
          expect(@session['my_model'].find().count).to eq(1)
        end
      end

      context "when document already exists in database" do
        it "update document in database" do
          id_1 = @session['my_model'].insert({name: 'name1'})
          instance = MyModel.find({_id: id_1}).first
          instance.name = 'name1'
          allow(instance).to receive('run_hook').and_return(true)
          instance.save_without_validation

          expect(instance).to have_received('run_hook').with(:before_save)
          expect(instance).to have_received('run_hook').with(:after_save)
          expect(instance._id).not_to eq(nil)
          expect(instance.name).to eq('name1')
          expect(@session['my_model'].find().count).to eq(1)
        end
      end

      context "when change document _id" do
        it "insert new document in database" do
          id_1 = @session['my_model'].insert({name: 'name1'})
          instance = MyModel.find({_id: id_1}).first
          instance._id = '123'
          allow(instance).to receive('run_hook').and_return(true)
          instance.save_without_validation

          expect(instance).to have_received('run_hook').with(:before_save)
          expect(instance).to have_received('run_hook').with(:after_save)
          expect(@session['my_model'].find().count).to eq(2)
          expect(@session['my_model'].find({'_id' => '123'}).first['name']).to eq('name1')
        end
      end
    end

    describe "save" do
      it "validate model" do
        instance = MyModel.new
        allow(instance).to receive('validate').and_return(true)
        instance.save
        expect(instance).to have_received('validate')
      end

      context "when document is valid" do
        it "save document" do
          instance = MyModel.new
          allow(instance).to receive('save_without_validation').and_return(true)
          instance.save
          expect(instance).to have_received('save_without_validation')
        end
      end

      context "when document is invalid" do
        it "don't save document" do
          instance = MyModel.new
          allow(instance).to receive('validate').and_return(false)
          allow(instance).to receive('save_without_validation').and_return(true)
          instance.save
          expect(instance).not_to have_received('save_without_validation')
        end
      end
    end

    describe "save!" do
      context "when document is invalid" do
        it "throw an exception" do
          instance = MyModel.new
          instance._errors = {name: 'blank'}
          allow(instance).to receive('validate').and_return(false)
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
          allow(instance).to receive('save_without_validation').and_return(true)
          instance.save!
          expect(instance).to have_received('save_without_validation')
        end
      end
    end

    describe "update" do
      it "update document" do
        id_1 = @session['my_model'].insert({name: 'name1', age: '22'})
        instance = MyModel.find({_id: id_1}).first
        instance.update({name: 'name2'})

        expect(@session['my_model'].find({'_id' => id_1}).first['name']).to eq('name2')
      end
    end

    describe "set" do
      it "update field" do
        id_1 = @session['my_model'].insert({name: 'name1'})
        instance = MyModel.find({_id: id_1}).first
        instance.set('name', 'name2')

        expect(@session['my_model'].find({'_id' => id_1}).first['name']).to eq('name2')
      end
    end

    describe "delete" do
      it "delete field from database" do
        id_1 = @session['my_model'].insert({name: 'name1'})
        instance = MyModel.find({_id: id_1}).first
        instance.destroy

        expect(@session['my_model'].find().count).to eq(0)
      end
    end

    describe "id" do
      it "return _id field in string format" do
        instance = MyModel.new
        instance.save
        expect(instance.id).to eq(instance._id.to_s)
      end
    end

    describe "validate" do
      it "return true when model is valid" do
        instance = MyModel.new
        allow(instance).to receive('run_hook').and_return(true)
        expect(instance.validate).to eq(true)
      end

      it "return false when model is invalid" do
        class MyModel2
          include Mongolow::Model

          validate do
            self._errors = {'intance' => 'invalid'}
          end
        end

        instance = MyModel2.new
        allow(instance).to receive('run_hook').and_call_original
        expect(instance.validate).to eq(false)
        expect(instance).to have_received('run_hook').with(:validate)
      end
    end

    describe "errors?" do
      it "return if model has errors" do
        instance = MyModel.new
        expect(instance.errors?).to eq(false)
        instance._errors = {}
        expect(instance.errors?).to eq(false)
        instance._errors = {name: 'invalid'}
        expect(instance.errors?).to eq(true)
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

        expect(instance.template).to eq({
          'id' => instance.id,
          'name' => 'm1',
          'email' => 'm1@email.com'
        })
        expect(instance.template('custom_template', {role: 'admin'})).to eq({
          'custom_name' => 'm1',
          'custom_email' => 'm1@email.com',
          'role' => 'admin'
        })
      end
    end
  end
end
