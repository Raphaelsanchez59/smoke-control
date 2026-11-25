module ChatsHelper
  # Transforme le Markdown de l'IA (## titres, **gras**, listes) en HTML propre
  def render_markdown(text)
    sanitize(Kramdown::Document.new(text.to_s, input: "GFM").to_html)
  end
end
