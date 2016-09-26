require_relative('html_processor')
require_relative('cpp_to_html_processor')
require('fileutils')
require('pathname')

def wbuilder(args)
    p "---- wbuilder start (" + __FILE__ + ") ----"
    projectDir = File.expand_path(args[0])
    p "---- error check start ----"
    checkCodeError(projectDir)
    p "---- build start ----"
    build(projectDir)
    p "---- wbuilder end ----"
end

def build(projectDir)
    srcDir  = projectDir.to_s + '/src'
    distDir = projectDir.to_s + '/dist'
    templateDir = projectDir.to_s + '/template'
    puts("projectDir  = #{projectDir}")
    puts("srcDir      = #{srcDir}")
    puts("distDir     = #{distDir}")
    puts("templateDir = #{templateDir}")

    # create empty directory 'dist'
    FileUtils.rm_rf(distDir)
    FileUtils.mkdir_p(distDir)

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
    Dir[srcDir + '/**/*.{css,png,gif,c,cpp,cc,h,hpp}'].each { |src|
        relative = Pathname.new(src).relative_path_from(Pathname.new(srcDir)).to_s
        dest = distDir + '/' + relative
        FileUtils.mkdir_p(File.dirname(dest)) #pre pripad ze neexistuje adresar
        FileUtils.cp(src, dest)
    }

    # c++ -> html
    Dir[srcDir + '/**/*.{c,cpp,cc,h,hpp}'].each { |srcFile|
        relative = Pathname.new(srcFile).relative_path_from(Pathname.new(srcDir)).to_s
        destFile = distDir + '/' + relative + ".html"
        # FileUtils.mkdir_p(File.dirname(dest)) # the directory is already created in previous step

        cppText = IO.read(srcFile)
        cppHtmlText = cpp_to_html(cppText, template, relative + ".html")
        IO.write(destFile, cppHtmlText)
    }

end

def checkCodeError(projectDir)
    srcDir = projectDir.to_s + '/src'
    tmpDir = projectDir.to_s + '/tmpCodeChecker' 

    FileUtils.rm_rf(tmpDir)
    FileUtils.mkdir_p(tmpDir)

    Dir[srcDir + '/**/*.{c,cpp,cc,h,hpp}'].each { |srcFile|
        tmpFile = tmpDir + '/' + File.basename(srcFile)
        FileUtils.cp(srcFile, tmpFile)

        compiler = (File.extname(tmpFile) == ".c" ? "gcc" : "g++")
        warningFlag = (/zadanie/ =~ srcFile ? "" : "-Wall")

        command ="#{compiler} #{warningFlag} -o #{tmpDir}/a.exe #{tmpFile}"
        p command
        `#{command}`
    }

   FileUtils.rm_rf(tmpDir)
end

if __FILE__ == $0
    wbuilder(ARGV)
end
