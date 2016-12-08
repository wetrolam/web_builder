require_relative('html_processor')

#Code segment
class Segment
  def initialize(beginPos:, endPos:, cssClass:)
    @beginPos = beginPos
    @endPos   = endPos
    @cssClass = cssClass
  end

  attr_reader :beginPos, :endPos, :cssClass
end

class Keyword
  @@cssClass = 'keyword'

  def self.createList(cpp, startDivList, endDivList)
    positions = [];
    $keywords.each{ |keyword|
      position = cpp.enum_for(:scan, %r[(?<=\W)#{keyword}(?=\W)]).map {Segment.new(beginPos: Regexp.last_match.begin(0), endPos:Regexp.last_match.end(0)-1, cssClass: @@cssClass)}
      positions += position
    }
    positions.each{ |item|
      startDivList[item.beginPos] << item.cssClass
      endDivList  [item.endPos  ] << item.cssClass
    }
  end
end

class Preprocessor
  @@cssClass = 'preprocessor'

  def self.createList(cpp, startDivList, endDivList)
    positions = cpp.enum_for(:scan, /^[ \t]*(#.*?)(?<!\\)$/m).map {Segment.new(beginPos: Regexp.last_match.begin(1), endPos:Regexp.last_match.end(1)-1, cssClass: @@cssClass)}
    positions.each{ |item|
      startDivList[item.beginPos] << item.cssClass
      endDivList  [item.endPos  ] << item.cssClass
    }
  end
end

class Comment
  CSS_CLASS = 'comment'

  def self.createList(cpp, startDivList, endDivList)
    positions = []
    positions += cpp.enum_for(:scan, /\/\/(.*?)(?<!\\)$/m).map {Segment.new(beginPos: Regexp.last_match.begin(0), endPos:Regexp.last_match.end(0)-1, cssClass: CSS_CLASS)}
    positions += cpp.enum_for(:scan, /\/\*(.*?)\*\//m).map {Segment.new(beginPos: Regexp.last_match.begin(0), endPos:Regexp.last_match.end(0)-1, cssClass: CSS_CLASS)}
    positions.each{ |item|
      startDivList[item.beginPos] << item.cssClass
      endDivList  [item.endPos  ] << item.cssClass
    }
  end
end

class String
  CSS_CLASS = 'data'

  def self.createList(cpp, startDivList, endDivList)
    positions = cpp.enum_for(:scan, /"(.*?)(?<!\\)"/m).map {Segment.new(beginPos: Regexp.last_match.begin(0), endPos:Regexp.last_match.end(0)-1, cssClass: CSS_CLASS)}
    positions.each{ |item|
      startDivList[item.beginPos] << item.cssClass
      endDivList  [item.endPos  ] << item.cssClass
    }
  end
end

# dokoncit regularny vyraz
class Number
  CSS_CLASS = 'data'

  def self.createList(cpp, startDivList, endDivList)
    positions = cpp.enum_for(:scan, /(\W)(-?\d+)(\W)/).map {Segment.new(beginPos: Regexp.last_match.begin(2), endPos:Regexp.last_match.end(2)-1, cssClass: CSS_CLASS)}
    positions.each{ |item|
      startDivList[item.beginPos] << item.cssClass
      endDivList  [item.endPos  ] << item.cssClass
    }
  end
end

class Char
  CSS_CLASS = 'data'

  def self.createList(cpp, startDivList, endDivList)
    positions = cpp.enum_for(:scan, /'.'/).map {Segment.new(beginPos: Regexp.last_match.begin(0), endPos:Regexp.last_match.end(0)-1, cssClass: CSS_CLASS)}
    positions.each{ |item|
      startDivList[item.beginPos] << item.cssClass
      endDivList  [item.endPos  ] << item.cssClass
    }
  end
end


# < ->  &lt < -> &gt;
def encode(letter)
  case letter
  when '<'
    return '&lt;'
  when '>'
    return '&gt;'
  else
    return letter
  end
end

def replaceSegmentsBySpaces(cpp, startDivList, endDivList, cssClass)
  withoutComment = ""
  insideComment = false
  for pos in 0..cpp.length-1
    segment = startDivList[pos].include?(cssClass)
    if segment
      insideComment = true
    end

    if insideComment
      withoutComment += ' '
    else
      withoutComment += cpp[pos]
    end

    segment = endDivList[pos].include?(cssClass)
    if segment
      insideComment = false
    end
  end

  return withoutComment
end

def cpp_to_html(cpp, template, titleTail)
    startDivList = Array.new(cpp.length) {[]}
    endDivList   = Array.new(cpp.length) {[]}
    Comment.createList(cpp, startDivList, endDivList)
    withoutComment = replaceSegmentsBySpaces(cpp, startDivList, endDivList, Comment::CSS_CLASS)

    String.createList(withoutComment, startDivList, endDivList)
    Number.createList(withoutComment, startDivList, endDivList)
    Char.createList(withoutComment, startDivList, endDivList)
    cppCode = replaceSegmentsBySpaces(withoutComment, startDivList, endDivList, String::CSS_CLASS)
    cppCode = replaceSegmentsBySpaces(cppCode       , startDivList, endDivList, Number::CSS_CLASS)
    cppCode = replaceSegmentsBySpaces(cppCode       , startDivList, endDivList, Char::CSS_CLASS)

    Preprocessor.createList(cpp, startDivList, endDivList)

    Keyword.createList(cppCode, startDivList, endDivList)

    html = ""
    for pos in 0..cpp.length-1
      classList = startDivList[pos]
      for i in 0...(classList.size())
        html += '<span class="' + classList[i] + '">'
      end

      # < ->  &lt < -> &gt;
      html += encode(cpp[pos])

      endDivList[pos].size().times {
        html += '</span>'
      }
    end

    # <pre><code> wrapping
    html = '<pre><code>' + html + '</code></pre>'

    # add <html><head><body> tags
    html = wrapHtmlBody(html, template, titleTail)

    # add style definition to html
    # every c++html file contains style for a single file download case
    style = IO.read(File.expand_path('../template/cpp.css', __FILE__))
    html.sub!(/(?=\s*<\/head>)/, "\n<style>\n#{style}\n</style>\n")

    return html
end

$keywords = [
'class', # have to be the first
'alignas',
'alignof',
'and',
'and_eq',
'asm',
'atomic_cancel',
'atomic_commit',
'atomic_noexcept',
'auto',
'bitand',
'bitor',
'bool',
'break',
'case',
'catch',
'char',
'char16_t',
'char32_t',
#'class', # have to be first
'compl',
'concept',
'const',
'constexpr',
'const_cast',
'continue',
'decltype',
'default',
'delete',
'do',
'double',
'dynamic_cast',
'else',
'enum',
'explicit',
'export',
'extern',
'false',
'float',
'for',
'friend',
'goto',
'if',
'inline',
'int',
'import',
'long',
'module',
'mutable',
'namespace',
'new',
'noexcept',
'not',
'not_eq',
'nullptr',
'operator',
'or',
'or_eq',
'private',
'protected',
'public',
'register',
'reinterpret_cast',
'requires',
'return',
'short',
'signed',
'sizeof',
'static',
'static_assert',
'static_cast',
'struct',
'switch',
'synchronized',
'template',
'this',
'thread_local',
'throw',
'true',
'try',
'typedef',
'typeid',
'typename',
'union',
'unsigned',
'using',
'virtual',
'void',
'volatile',
'wchar_t',
'while',
'xor',
'xor_eq',

'override',
'final',
'transaction_safe',
'transaction_safe_dynamic',
]

$preprocessor = [
'if',
'elif',
'else',
'endif',
'defined',
'ifdef',
'ifndef',
'define',
'undef',
'include',
'line',
'error',
'pragma',
]
