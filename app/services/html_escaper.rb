# Neutraliza <, > y & para que el texto generado no se interprete como HTML.
module HtmlEscaper
  def self.escape(text) = ERB::Util.html_escape(text.to_s)
end
