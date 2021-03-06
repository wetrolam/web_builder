
def wrapHtmlBody(bodyText, template, titleTail = nil)
    html = template.sub(/(?<=<body>).*(?=<\/body>)/m) {|str| "\n\n#{bodyText}\n\n"} # used the block form of String.sub to avoid back-references in 'bodyText'
    if titleTail != nil
        html.sub!(/(?<=<title>).*(?=<\/title>)/m, "\\0 - #{titleTail}")
    end
    return html
end

def processHtml(inputHtml)
    outputHtml = inputHtml.gsub(/#A\((.*?)\)/) { |str|
        sourceFile = str.gsub(/#A\((.*)\)/, '\1').strip()
        htmlFile = sourceFile + '.html'
        '<a href="' + sourceFile +'"> ' + File.basename(sourceFile) + ' </a> <a href="' + htmlFile + '"> (html) </a>'
    }
    return outputHtml
end
