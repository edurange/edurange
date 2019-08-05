module ApplicationHelper

  def display_base_errors resource
    return '' if (resource.errors.empty?) or (resource.errors[:base].empty?)
    messages = resource.errors[:base].map { |msg| content_tag(:p, msg) }.join
    html = <<-HTML
    <div class="alert alert-error alert-block">
      <button type="button" class="close" data-dismiss="alert">&#215;</button>
      #{messages}
    </div>
    HTML
    html.html_safe
  end
  def javascript(*files)
    content_for(:head) { javascript_include_tag(*files) }
  end

  def markdown(content)
    renderer = Redcarpet::Render::HTML
    parser = Redcarpet::Markdown.new(
      renderer,
      fenced_code_blocks: true,
#      disable_indented_code_blocks: false
    )
    raw(parser.render(content))
  end

end
