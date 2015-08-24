# Mongolow
Simple Ruby Object Mapper for Mongodb.  
Mongolow uses [mongo-ruby-driver](https://github.com/mongodb/mongo-ruby-driver) to manage mongodb database.

## Basic Usage

### Initialize

#### Manually

    Mongolow::Driver.initialize('127.0.0.1', 27017, 'mongolow_test')
    
#### Config file

You can use `config/mongolow.yml` to define environments configurations.  
Mongolow uses `ENV['ENV']` to select environment.
    
    development:
      host: '127.0.0.1'
      port: 27017
      database: 'mongolow_development'
      
    production:
      host: '127.0.0.1'
      port: 27017
      database: 'mongolow_production'


Use default config file:

    Mongolow.initialize

Select other config file:

    Mongolow::Driver.initialize_from_file('path/other_file.yml')

#### Remove mongo log

Mongolow creates log file in `log/` directory. To remove it add:

    Mongo::Logger.logger = Logger.new('/dev/null')

### Define model

```ruby
class Person
  include Mongolow::Model

  field :name
  field :email
end
```

#### Private fields

Mongolow uses the next private fields **DON'T OVERWRITE !!**:

* _id
* _errors
* _hooks

Mongolow doesn't save or represent private fields.

#### Virtual fields

You can define virtual fields that don't be persisted in database but it can be used in model functions and hooks.

```ruby
class Person
  include Mongolow::Model

  field :name
  attr_read :age
end

person = Person.new({name: 'John', age: 15})
person.age # => 15
person.save

Person.last.name # => 'John'
Person.last.age  # => nil
```

### Class Methods

* new(hash_initial_values)
* find(query)
* find_by_id(id)
* count
* first(query)
* destroy_all
* destroy_by_id(id)

### Cursor methods

* first
* all
* count
* limit(n)
* skyp(n)
* find(query)
* sort(query)

### Instance Methods

* save
* save!
* save_without_validation
* update(params)
* set(field_name, field_value)
* destroy
* reload
* validate!
* errors?
* template
* changed
* changed?(field_name)

### Example

You can see complete example [here](https://github.com/rjurado01/mongolow/blob/master/spec/example_spec.rb).

## Validations

All Mongolow models have `_errors` field by default to store errors.  
You can define your own validations using validate hook.

```ruby
class Person
  include Mongolow::Model

  field :name

  validate do
    self._errors['name'] = 'blank' unless self.name
  end
end
```

Mongolow call validate method before save any model.  
If validate method returns false, Mongolow don't save the model.

### Methods

You can use mongolow validations methods in validate block:

* `presence_of(field_name, options={}) # message => blank`
* `inclusion_of(field_name, values, options={}) # message => inclusion`
* `uniquenes_of(field_name, options={}) # message => taken`
* `match_of(field_name, value, options={}) # message => match`

Example:

```ruby
class Car
  include Mongolow::Model

  field :type

  validate do
    presence_of :type, {message: 'presence'}  # add presence error
    inclusion_of :type, [:type1, :type2]  # add default inclusion error
  end
end
```
## Relationships

Mongolow doesn't support relationships management.  
You can define your own relationships using fields and methods.

## Hooks

Mongolow uses [hooks](https://github.com/apotonick/hooks) gem. You can use next hooks:

* after_initialize
* before_save
* after_save
* before_destroy
* after_destroy

### Example

```ruby
class Person
  include Mongolow::Model

  field :name

  before_save do
    self.name = 'My name'
  end
end
```

## Changes

Mongolow saves a copy of fields values when you create new instace of document or save it.

```ruby
class Post
  include Mongolow::Model

  field :title
  field :text
end

p = Post.new({title: 'Title1', text: 'Example text 1.'})
p._old_values
# {}

p.save
p.title = 'Title2'
p._old_values
# {'title' => 'Title1', 'text' => 'Example text 1.'}

p.save
p._old_values
# {'title' => 'Title2', 'text' => 'Example text 1.'}
```

## Templates

You can use `template` method for get model hash representation.  
You can also define your own template methods and call its with `template`.

```ruby
class Post
  include Mongolow::Model

  field :title
  field :text

  def custom_template(options)
    return {
        id: self._id.to_s
        title: self.title,
        text: self.text,
        author: options['author']
    }
  end
end

p = Post.new({title: 'Title1', 'text' => 'Example text 1.'})
p.save
p.template
# {
#   "_id": {
#     "$oid": "55539336ab8bae1fdb000001"
#   },
#   "title": "Title1",
#   "text": "Example text 1."
# }

p.template('custom_template', {'author' => 'John'})
# {
#   "id": "55539336ab8bae1fdb000001",
#   "title": "Title1",
#   "text": "Example text 1.",
#   "author": "John"
# }
```
