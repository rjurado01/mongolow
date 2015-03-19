# Mongolow
Simple Ruby Object Mapper for Mongodb.  
Mongolow uses [mongo-ruby-driver](https://github.com/mongodb/mongo-ruby-driver) to manage mongodb database.

## Basic Usage

### Initialize

    Mongolow::Driver.initialize('127.0.0.1', 27017, 'mongolow_test')

### Define model

```ruby
class Person
  import Mongolow::Model
  
  field :name
  field :email
end
```

### Class Methods

* new(hash_initial_values)
* find(query)
* count
* first
* destroy_all

### Instance Methods

* save
* set(field_name, field_value)
* destroy

## Validations

All Mongolow models have `_errors` field by default to store errors.  
You can define your own validations using method validate.

```ruby
class Person
  import Mongolow::Model
  
  field :name
  
  def validate
    self._errors = {}
    self._errors['name'] = 'blank' unless self.name
    self._errors.empty?
  end
end
```

Mongolow call validate method before save any model.  
If validate method returns false, Mongolow don't save the model.

## Relationships

Mongolow doesn't support relationships management.  
You can define your own relationships using fields and methods.

## Callbacks

You can define this callbacks in your model:

* after_initialize
* before_validate
* before_save
* after_save
* before_destroy
* after_destroy

### Example

```ruby
class Person
  import Mongolow::Model
  
  field :name
  
  def before_save
    self.name = 'My name'
  end
end
```
