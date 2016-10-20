require_relative('html_processor')

def cpp_to_html(cpp, template, titleTail)
    # < ->  &lt < -> &gt;
    html = cpp.gsub('<', '&lt;').gsub('>', '&gt;')

    # keywords
    $keywords.each{ |keyword|
        html.gsub!(%r[(\W)#{keyword}(\W)], "\\1<span class=\"keyword\">#{keyword}</span>\\2")
    }

    # comments
    html.gsub!(/\/\/(.*)$/, "<span class=\"comment\">\\0</span>") # backslash at the end of a line is not solved!
    html.gsub!(/\/\*(.*?)\*\//m, "<span class=\"comment\">\\0</span>")

    # preprocessor
    # html.gsub!(%r[^\s*\#.*$], "<span class=\"preprocessor\">\\0</span>") # backslash at the end of a line is not solved!
    html.gsub!(/^[ \t]*#.*$/, "<span class=\"preprocessor\">\\0</span>") # backslash at the end of a line is not solved!

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
