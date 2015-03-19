require 'spec_helper'

describe "Model inheritance example" do
  before :all do
    Mongolow::Driver.initialize('127.0.0.1', 27017, 'mongolow_test')
    @session = MongoClient.new( '127.0.0.1', 27017 ).db( 'mongolow_test' )
  end

  it "everithing works fine" do
    @session['person'].drop

    class Person
      include Mongolow::Model

      field :name
      field :age
    end

    # check new
    person1 = Person.new({name: 'p1', age: '25'})
    person2 = Person.new({name: 'p2'})
    person1.save
    person2.save

    # check save
    db_persons = @session['person'].find().to_a
    db_persons.count.should == 2
    db_persons[0]['name'].should == 'p1'
    db_persons[0]['age'].should == '25'
    db_persons[1]['name'].should == 'p2'
    db_persons[1]['age'].should == nil

    # check update
    person2.age = '26'
    person2.save
    db_person = @session['person'].find({'_id' => person2._id}).first
    db_person['age'].should == '26'

    # check set
    person2.set('age', nil)
    db_person = @session['person'].find({'_id' => person2._id}).first
    db_person['age'].should == nil

    # check destroy
    person1.destroy
    person2.destroy
    db_persons = @session['person'].find().count.should == 0
  end
end
