require "../spec_helper"

include ContextHelper

private class TestComponent < Lucky::BaseComponent
  def render
    text "TestComponent"
  end
end

private class ComplexTestComponent < Lucky::BaseComponent
  needs title : String

  def render
    text @title
    img src: asset("images/logo.png")
    mount(TestComponent)
  end
end

private class ComplexInstanceTestComponent < Lucky::BaseComponent
  needs title : String

  def render
    text @title
    img src: asset("images/logo.png")
    component = TestComponent.new
    mount_instance(component)
  end
end

private class ComponentWithBlock < Lucky::BaseComponent
  needs name : String

  def render
    yield @name
  end
end

private class ComponentWithBlockAndNoBlockArgs < Lucky::BaseComponent
  def render
    yield
  end
end

class User < Avram::Model
  table do
    column name : String
  end
end

class SaveUser < User::SaveOperation
  permit_columns name
end

class Shared::FieldErrors(T) < Lucky::BaseComponent
  needs attribute : Avram::PermittedAttribute(T)

  def render
  end
end


class Shared::Field(T) < Lucky::BaseComponent
  needs attribute : Avram::PermittedAttribute(T)

  def render
    tag_defaults field: attribute do |input_builder|
      yield input_builder
    end

    mount Shared::FieldErrors, attribute
    # works if I inline the definition of `mount`
    # print_component_comment(Shared::FieldErrors) do
    #   Shared::FieldErrors.new(attribute).view(view).render
    # end
  end

  # works if I copy and paste the methods directly into the class
  # def mount(component : Lucky::BaseComponent.class, *args, **named_args) : Nil
  #   print_component_comment(component) do
  #     component.new(*args, **named_args).view(view).render
  #   end
  # end

  # def mount(component : Lucky::BaseComponent.class, *args, **named_args) : Nil
  #   print_component_comment(component) do
  #     component.new(*args, **named_args).view(view).render do |*yield_args|
  #       yield *yield_args
  #     end
  #   end
  # end

  # Use a text_input by default
  def render
    render &.text_input
  end
end


private class TestMountPage
  include Lucky::HTMLPage

  def render
    mount(ComplexTestComponent, title: "passed_in_title")
    mount(ComponentWithBlockAndNoBlockArgs) do
      text "Block without args"
    end
    mount(ComponentWithBlock, "Jane") do |name|
      text name.upcase
    end
    mount Shared::Field, attribute: SaveUser.new.name, label_text: "Name"
    view
  end
end

private class TestMountInstancePage
  include Lucky::HTMLPage

  def render
    component = ComplexInstanceTestComponent.new(title: "passed_in_title")
    mount_instance(component)

    component = ComponentWithBlockAndNoBlockArgs.new
    mount_instance(component) do
      text "Block without args"
    end

    component = ComponentWithBlock.new("Jane")
    mount_instance(component) do |name|
      text name.upcase
    end

    view
  end
end

describe "components rendering" do
  it "renders to a page" do
    contents = TestMountPage.new(build_context).render.to_s

    contents.should contain("passed_in_title")
    contents.should contain("TestComponent")
    contents.should contain("/images/logo-with-hash.png")
    contents.should contain("JANE")
    contents.should contain("Block without args")
    contents.should_not contain("<!--")
  end

  it "renders to a string" do
    html = ComplexTestComponent.new(title: "passed_in_title").render_to_string

    html.should contain("passed_in_title")
  end

  it "prints a comment when configured to do so" do
    Lucky::HTMLPage.temp_config(render_component_comments: true) do
      contents = TestMountPage.new(build_context).render.to_s
      contents.should contain("<!-- BEGIN: ComplexTestComponent spec/lucky/component_spec.cr -->")
      contents.should contain("<!-- END: ComplexTestComponent -->")
      contents.should contain("<!-- BEGIN: ComponentWithBlock spec/lucky/component_spec.cr -->")
      contents.should contain("<!-- END: ComponentWithBlock -->")
    end
  end

  context "mounted instance" do
    it "renders to a page" do
      contents = TestMountInstancePage.new(build_context).render.to_s

      contents.should contain("passed_in_title")
      contents.should contain("TestComponent")
      contents.should contain("/images/logo-with-hash.png")
      contents.should contain("JANE")
      contents.should contain("Block without args")
      contents.should_not contain("<!--")
    end

    it "renders to a string" do
      html = ComplexInstanceTestComponent.new(title: "passed_in_title").render_to_string

      html.should contain("passed_in_title")
    end

    it "prints a comment when configured to do so" do
      Lucky::HTMLPage.temp_config(render_component_comments: true) do
        contents = TestMountInstancePage.new(build_context).render.to_s
        contents.should contain("<!-- BEGIN: ComplexInstanceTestComponent spec/lucky/component_spec.cr -->")
        contents.should contain("<!-- END: ComplexInstanceTestComponent -->")
        contents.should contain("<!-- BEGIN: ComponentWithBlock spec/lucky/component_spec.cr -->")
        contents.should contain("<!-- END: ComponentWithBlock -->")
      end
    end
  end
end
