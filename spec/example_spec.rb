require 'spec_helper'

describe "Model inheritance example" do
  before :all do
    Mongolow::Driver.initialize('127.0.0.1', 27017, 'mongolow_test')
    @client = Mongo::Client.new('mongodb://127.0.0.1:27017/mongolow_test')
  end

  it "everithing works fine" do
    @client['person'].drop

    class Person
      include Mongolow::Model

      field :name
      field :age
      field :email

      before_save do
        self.age = '23' unless self.age
      end

      validate do
        self._errors = {}
        self._errors['email'] = 'black' unless self.email
        self._errors.empty?
      end
    end

    # check new
    person1 = Person.new({name: 'p1', age: '25', email: 'email1@email.com'})
    person2 = Person.new({name: 'p2', email: 'email2@email.com'})
    expect(person1.name).to eq('p1')
    expect(person2.name).to eq('p2')

    # check save
    person1.save
    person2.save
    db_persons = @client['person'].find.to_a
    expect(db_persons.count).to eq(2)
    expect(db_persons[0]['name']).to eq('p1')
    expect(db_persons[0]['age']).to eq('25')
    expect(db_persons[1]['name']).to eq('p2')
    expect(db_persons[1]['age']).to eq('23')

    person2.age = '26'
    person2.save
    expect(@client['person'].find({'_id' => person2._id}).first['age']).to eq('26')

    # check update
    person2.update({name: 'new_name', age: '30'})
    db_person = @client['person'].find({'_id' => person2._id}).first
    expect(db_person['name']).to eq('new_name')
    expect(db_person['age']).to eq('30')

    # check set
    person2.set('age', nil)
    expect(@client['person'].find({'_id' => person2._id}).first['age']).to eq(nil)

    # check destroy
    person1.destroy
    person2.destroy
    expect(@client['person'].find().count).to eq(0)

    # check validation
    person1 = Person.new({name: 'p1'})
    person1.save
    expect(@client['person'].find.count).to eq(0)
    expect(person1._errors).to eq({'email' => 'black'})
    expect(person1.errors?).to eq(true)
    person1.email = 'user1@email.com'
    expect(person1.validate).to eq(true)

    # check template
    person1 = Person.new({name: 'p1', age: '25', email: 'email1@email.com'})
    person1.save
    expect(person1.template).to eq(
      {'id' => person1.id, 'name' => 'p1', 'age' => '25', 'email' => 'email1@email.com'})

    # check find
    person1 = Person.new({name: 'p10', age: '40', email: 'email10@email.com'})
    person2 = Person.new({name: 'p11', age: '40', email: 'email11@email.com'})
    person1.save
    person2.save
    cursor = Person.find({age: '40'})
    expect(cursor.count).to eq(2)
    expect(cursor.find({name: 'p10'}).count).to eq(1)

    # close connection
    # Mongolow::Driver.close
  end
end
