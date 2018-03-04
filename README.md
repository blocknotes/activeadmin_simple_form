# ActiveAdmin SimpleForm [![Gem Version](https://badge.fury.io/rb/activeadmin_simple_form.svg)](https://badge.fury.io/rb/activeadmin_simple_form)

An Active Admin plugin to use Simple Form in place of Formtastic in edit views.

WARNING: this component is a Beta version, some Active Admin functionalities could not work as expected

## Install

- Add to your Gemfile: gem 'activeadmin_simple_form'
- Execute bundle
- Create the Simple Form config initializer: `rails generate simple_form:install`
- Add to the config the wrapper used for the fields in *inputs* blocks:

```rb
  config.wrappers :inputs_container, tag: :li, class: :input, hint_class: :field_with_hint, error_class: :field_with_errors do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label_input
    b.use :hint,  wrap_with: { tag: :span, class: :hint }
    b.use :error, wrap_with: { tag: :span, class: :error }
  end
```

## Example

- Author model example:

```rb
  form do |f|
    f.inputs 'Informations' do
      f.input :name
      f.input :age
      f.association :country  # using input for associations is not supported
      f.has_many :articles do |ff|
        ff.input :title
        ff.input :description
        ff.input :published
        ff.input :_destroy, as: :boolean, required: false unless ff.object.new_record?
      end
    end
    f.actions
  end
```

## Do you like it? Star it!

If you use this component just star it. A developer is more motivated to improve a project when there is some interest.

Take a look at [other ActiveAdmin components](https://github.com/blocknotes?utf8=✓&tab=repositories&q=activeadmin&type=source) that I made if you are curious.

## Contributors

- [Mattia Roccoberton](http://blocknot.es) - creator, maintainer

## License

[MIT](LICENSE.txt)
