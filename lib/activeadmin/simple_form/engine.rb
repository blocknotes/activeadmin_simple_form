require 'active_admin'

module ActiveAdmin
  module SimpleForm
    class Engine < ::Rails::Engine
      engine_name 'activeadmin_simple_form'
    end
  end
end

module ActiveAdmin
  module SimpleForm
    class SimpleFormBuilder < ::SimpleForm::FormBuilder
      include MethodOrProcHelper
      include ::Formtastic::Helpers::InputsHelper

      attr_accessor :already_in_an_inputs_block

      # def initialize(*)
      #   raise Exception.new( 'define a "inputs_container" simple_form wrapper' ) unless ::SimpleForm.wrappers['inputs_container']
      #   ::SimpleForm.wrappers['inputs_container'] ||= ::SimpleForm::Wrappers::Root.new [], tag: :li
      #   super
      # end

      def action(method, options = {})  # -> Formtastic::Helpers::ActionHelper
        case method
        when :button, :reset
          button :button, options[:label], type: method
        when :submit
          button :submit, options[:label]
        else
          template.link_to options[:label], options[:url]
        end
      end

      def assoc_heading(assoc)  # -> ActiveAdmin::FormBuilder
        object.class.reflect_on_association(assoc).klass.model_name.
          human(count: ::ActiveAdmin::Helpers::I18n::PLURAL_MANY_COUNT)
      end

      def cancel_link(url = {action: "index"}, html_options = {}, li_attrs = {})  # -> ActiveAdmin::FormBuilder
        li_attrs[:class] ||= "cancel"
        li_content = template.link_to ::I18n.t('active_admin.cancel'), url, html_options
        template.content_tag(:li, li_content, li_attrs)
      end

      def has_many(assoc, options = {}, &block)  # -> ActiveAdmin::FormBuilder
        # remove options that should not render as attributes
        custom_settings = :new_record, :allow_destroy, :heading, :sortable, :sortable_start
        builder_options = {new_record: true}.merge! options.slice  *custom_settings
        options         = {for: assoc      }.merge! options.except *custom_settings
        options[:class] = [options[:class], "inputs has_many_fields"].compact.join(' ')
        sortable_column = builder_options[:sortable]
        sortable_start  = builder_options.fetch(:sortable_start, 0)

        if sortable_column
          options[:for] = [assoc, sorted_children(assoc, sortable_column)]
        end

        html = "".html_safe
        unless builder_options.key?(:heading) && !builder_options[:heading]
          html << template.content_tag(:h3) do
            builder_options[:heading] || assoc_heading(assoc)
          end
        end

        html << template.capture do
          form_block = proc do |has_many_form|
            index    = parent_child_index options[:parent] if options[:parent]
            block_contents = template.capture do
              block.call(has_many_form, index)
            end
            template.concat(block_contents)
            template.concat has_many_actions(has_many_form, builder_options, "".html_safe)
          end

          template.assigns[:has_many_block] = true
          contents = without_wrapper { inputs(options, &form_block) } || "".html_safe

          if builder_options[:new_record]
            contents << js_for_has_many(assoc, form_block, template, builder_options[:new_record], options[:class])
          else
            contents
          end
        end

        tag = @already_in_an_inputs_block ? :li : :div
        html = template.content_tag(tag, html, class: "has_many_container #{assoc}", 'data-sortable' => sortable_column, 'data-sortable-start' => sortable_start)
        template.concat(html) if template.output_buffer
        html
      end

      def input(attribute_name, options = {}, &block)  # -> SimpleForm::FormBuilder
        options = @defaults ? @defaults.deep_dup.deep_merge(options) : options.dup
        options[:wrapper] = :inputs_container if @already_in_an_inputs_block && !options[:wrapper] && ::SimpleForm.wrappers['inputs_container']
        options[:wrapper_html] ||= {}

        input = find_input(attribute_name, options, &block)
        unless options[:wrapper_html][:class]
          case input.input_type
          when :date, :datetime, :time
            options[:wrapper_html][:class] = 'fragment'
          end
        end
        wrapper = find_wrapper(input.input_type, options)

        html = wrapper.render input
        template.concat(html) if template.output_buffer && template.assigns[:has_many_block]
        html
      end

      # def object
      #   # template.resource
      #   form_builder.object
      # end

    protected

      def has_many_actions(has_many_form, builder_options, contents)  # -> ActiveAdmin::FormBuilder
        if has_many_form.object.new_record?
          contents << template.content_tag(:li) do
            template.link_to I18n.t('active_admin.has_many_remove'), "#", class: 'button has_many_remove'
          end
        elsif call_method_or_proc_on(has_many_form.object,
                                    builder_options[:allow_destroy],
                                    exec: false)

          has_many_form.input(:_destroy, as: :boolean,
                              wrapper_html: {class: 'has_many_delete'},
                              label: I18n.t('active_admin.has_many_delete'))
        end

        if builder_options[:sortable]
          has_many_form.input builder_options[:sortable], as: :hidden

          contents << template.content_tag(:li, class: 'handle') do
            I18n.t('active_admin.move')
          end
        end

        contents
      end

      def sorted_children(assoc, column)  # -> ActiveAdmin::FormBuilder
        object.public_send(assoc).sort_by do |o|
          attribute = o.public_send column
          [attribute.nil? ? Float::INFINITY : attribute, o.id || Float::INFINITY]
        end
      end

    private

      def js_for_has_many(assoc, form_block, template, new_record, class_string)  # -> ActiveAdmin::FormBuilder
        assoc_reflection = object.class.reflect_on_association assoc
        assoc_name       = assoc_reflection.klass.model_name
        placeholder      = "NEW_#{assoc_name.to_s.underscore.upcase.gsub(/\//, '_')}_RECORD"
        opts = {
          for: [assoc, assoc_reflection.klass.new],
          class: class_string,
          for_options: { child_index: placeholder }
        }
        html = template.capture{ inputs_for_nested_attributes opts, &form_block }
        text = new_record.is_a?(String) ? new_record : I18n.t('active_admin.has_many_new', model: assoc_name.human)

        template.link_to text, '#', class: "button has_many_add", data: {
          html: CGI.escapeHTML(html).html_safe, placeholder: placeholder
        }
      end

      def without_wrapper  # -> ActiveAdmin::FormBuilder
        is_being_wrapped = @already_in_an_inputs_block
        @already_in_an_inputs_block = false

        html = yield

        @already_in_an_inputs_block = is_being_wrapped
        html
      end
    end
  end
end

ActiveAdmin::Views::ActiveAdminForm.class_eval do
  def build(resource, options = {}, &block)  # -> ActiveAdmin::Views::ActiveAdminForm
    @resource = resource
    options = options.deep_dup
    options[:builder] ||= ActiveAdmin::SimpleForm::SimpleFormBuilder  # change 1 - was ActiveAdmin::FormBuilder
    form_string = helpers.simple_form_for(resource, options) do |f|   # change 2 - was helpers.semantic_form_for
      @form_builder = f
    end

    @opening_tag, @closing_tag = split_string_on(form_string, "</form>")
    instance_eval(&block) if block_given?

    # Rails sets multipart automatically if a file field is present,
    # but the form tag has already been rendered before the block eval.
    if multipart? && @opening_tag !~ /multipart/
      @opening_tag.sub!(/<form/, '<form enctype="multipart/form-data"')
    end
  end
end
