require_relative('html_processor')
require_relative('cpp_to_html_processor')
require_relative('cpp')
require('fileutils')
require('pathname')

def wbuilder(args)
    p "---- wbuilder start (" + __FILE__ + ") ----"
    projectDir = File.expand_path(args[0])
    clearDistributionDirectory(projectDir)
    p "---- build start ----"
    build(projectDir)
    p "---- error check start ----"
    checkCodeError(projectDir)
    p "---- wbuilder end ----"
end

#Create a fresh distribution directory (output directory)
def clearDistributionDirectory(projectDir)
    distDir = projectDir.to_s + '/dist'
    FileUtils.rm_rf(distDir)
    FileUtils.mkdir_p(distDir)
end

def build(projectDir)
    srcDir  = projectDir.to_s + '/src'
    distDir = projectDir.to_s + '/dist'
    templateDir = projectDir.to_s + '/template'
    puts("projectDir  = #{projectDir}")
    puts("srcDir      = #{srcDir}")
    puts("distDir     = #{distDir}")
    puts("templateDir = #{templateDir}")

    # get html template
    template = IO.read(templateDir + '/template.html')

    # create html files
    Dir[srcDir + "/**/*.html.text"].each { |inHtmlFile|
        puts inHtmlFile.to_s

        inHtmlFileRelative = Pathname.new(inHtmlFile).relative_path_from(Pathname.new(srcDir))
        outHtmlFile =  distDir + '/' + inHtmlFileRelative.to_s.chomp('.text')
        puts outHtmlFile

        inHtml  = IO.read(inHtmlFile.to_s)
        outHtml = wrapHtmlBody(inHtml, template)
        outHtml = processHtml(outHtml)

        FileUtils.mkdir_p(File.dirname(outHtmlFile)) # pre pripad ze neexistuje adresar
        IO.write(outHtmlFile, outHtml)
    }

    # copy files without transformation needed
    Dir[srcDir + '/**/*.{css,png,gif,txt}'].each { |src|
        relative = Pathname.new(src).relative_path_from(Pathname.new(srcDir)).to_s
        dest = distDir + '/' + relative
        FileUtils.mkdir_p(File.dirname(dest)) #pre pripad ze neexistuje adresar
        FileUtils.cp(src, dest)
    }

    # copy (and modify) source files
    Dir[srcDir + '/**/*.{c,cpp,cc,h,hpp}'].each { |srcFile|
        distributeCpp(srcFile, srcDir, distDir)
    }

    # c++ -> html
    Dir[distDir + '/**/*.{c,cpp,cc,h,hpp}'].each { |cppFile|
        cppHtmlFile = cppFile + ".html"
        titleTail = File.basename(cppHtmlFile)
        cppText = IO.read(cppFile)
        cppHtmlText = cpp_to_html(cppText, template, titleTail)
        IO.write(cppHtmlFile, cppHtmlText)
    }

end

if __FILE__ == $0
    wbuilder(ARGV)
end
