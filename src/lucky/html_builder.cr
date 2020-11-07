require "./tags/**"
require "./page_helpers/**"
require "./mount_component"

module Lucky::HTMLBuilder
  include Lucky::BaseTags
  include Lucky::CustomTags
  include Lucky::LinkHelpers
  include Lucky::FormHelpers
  include Lucky::SpecialtyTags
  include Lucky::Assignable
  include Lucky::AssetHelpers
  include Lucky::NumberToCurrency
  include Lucky::TextHelpers
  include Lucky::HTMLTextHelpers
  include Lucky::UrlHelpers
  include Lucky::TimeHelpers
  include Lucky::ForgeryProtectionHelpers
  include Lucky::HelpfulParagraphError
  include Lucky::RenderIfDefined
  include Lucky::TagDefaults

  abstract def view : IO

  def perform_render : IO
    render
    view
  end

  def mount(component : Lucky::BaseComponent.class, *args, **named_args) : Nil
    component.new(*args, **named_args).view(view).render
  end

  def mount(component : Lucky::BaseComponent.class, *args, **named_args) : Nil
    component.new(*args, **named_args)
      .view(view)
      .render { |*yield_args| yield *yield_args }
  end
end
