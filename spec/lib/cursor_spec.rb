require 'spec_helper'

describe Mongolow::Cursor do
  before :all do
    class Person
      attr_accessor :name

      def initialize(hash)
        @name = hash['name']
      end

      def self.coll_name
        :persons
      end
    end
  end

  before do
    allow_any_instance_of(Person).to receive(:set_old_values).and_return(true)
  end

  describe 'Functionality' do
    context 'when create new instance' do
      it 'everything works fine' do
        expect(Mongolow::Cursor.new(Person)).not_to eq(nil)
      end
    end
  end

  describe 'Methods' do
    before do
      @instance = Mongolow::Cursor.new(Person, {name: 'name1'}, {limit: 1})
      allow(@instance).to receive(:view).and_return([{'name' => 'name1'}, {'name' => 'name2'}])
    end

    describe '#first' do
      it 'return first document' do
        document = @instance.first
        expect(document.class).to eq(Person)
        expect(document.name).to eq('name1')
      end

      it 'call set_old_values' do
        expect(@instance.first).to have_received(:set_old_values)
      end
    end

    describe '#all' do
      it 'return all documents' do
        documents = @instance.all
        expect(documents.size).to eq(2)
        expect(documents[0].class).to eq(Person)
        expect(documents[0].name).to eq('name1')
        expect(documents[1].class).to eq(Person)
        expect(documents[1].name).to eq('name2')
      end

      it 'call set_old_values' do
        @instance.all.each do |document|
          expect(document).to have_received(:set_old_values)
        end
      end
    end

    describe '#count' do
      it 'return number of documents' do
        expect(@instance.count).to eq(2)
      end
    end

    describe '#limit' do
      it 'add limit option' do
        @instance.limit(1)
        expect(@instance.options[:limit]).to eq(1)
      end
    end

    describe '#skip' do
      it 'add skip option' do
        @instance.skip(1)
        expect(@instance.options[:skip]).to eq(1)
      end
    end

    describe '#sort' do
      it 'add sort option' do
        @instance.sort(name: 1)
        expect(@instance.options[:sort]).to eq(name: 1)
      end
    end

    describe '#find' do
      it 'merge filter and options' do
        @instance.find({surname: 'surname1'}, {limit: 3})
        expect(@instance.filter).to eq(name: 'name1', surname: 'surname1')
      end
    end

    describe '#destroy_all' do
      it 'destroy cursor documents' do
        count = 0
        allow_any_instance_of(Person).to receive(:destroy) { count += 1 }
        @instance.destroy_all
        expect(count).to eq(2)
      end
    end

    describe '#view' do
      it 'creates new Mongo::Collection::View' do
        collection = {}
        allow(collection).to receive(:find).and_return(true)
        allow(Mongolow::Driver).to receive(:client).and_return(persons: collection)
        allow(@instance).to receive(:view).and_call_original

        expect(collection).to receive(:find)
        @instance.send(:view)
      end
    end
  end
end
