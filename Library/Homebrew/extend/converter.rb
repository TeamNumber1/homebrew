begin
  require 'rubygems'
  require 'kramdown'
rescue LoadError => e
  # pass
else
  class Kramdown::Document
    def type
      :document
    end
  end
  class Converter < ::Kramdown::Converter::Base
    def convert(el, opts = {})
      send("convert_#{el.type}", el, opts)
    end
    def convert_document(doc, opts = {})
      convert_root doc.root, opts
    end
    def convert_root(root, opts = {})
      inner(root, opts)
    end

    def inner(el, opts = {})
      result = ''
      el.children.each do |e|
        result << convert(e, opts)
      end
      result
    end

    def convert_p(p, opts)
      inner(p, opts) + "\n"
    end
    def convert_text(t, opts)
      t.value
    end
    def convert_codespan(c, opts)
      c.value
    end
    def convert_html_element(el, opts)
      el.value + inner(el, opts)
    end
    def convert_blank(b, opts)
      b.value
    end
    def convert_codeblock(c, opts)
      indent_codeblock(c.value + (inner c, opts))
    end

    def indent_codeblock(content)
      content.split("\n").map {|l| "    " + l }.join("\n")
    end

  end
end
