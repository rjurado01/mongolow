# Mongolow
Simple Ruby Object Mapper for Mongodb.  
Mongolow uses [mongo-ruby-driver](https://github.com/mongodb/mongo-ruby-driver) to manage mongodb database.

## Basic Usage

### Initialize

    Mongolow::Driver.initialize('127.0.0.1', 27017, 'mongolow_test')

### Define model

```ruby
class Person
  include Mongolow::Model

  field :name
  field :email
end
```

### Class Methods

* new(hash_initial_values)
* find(query)
* find_by_id(id)
* count
* first(query)
* destroy_all
* destroy_by_id(id)

### Instance Methods

* save
* set(field_name, field_value)
* destroy
* template

### Example

You can see complete example [here](https://github.com/rjurado01/mongolow/blob/master/spec/example_spec.rb).

## Validations

All Mongolow models have `_errors` field by default to store errors.  
You can define your own validations using method validate.

```ruby
class Person
  include Mongolow::Model

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
  include Mongolow::Model

  field :name

  def before_save
    self.name = 'My name'
  end
end
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
