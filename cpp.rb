
$cppSourceVersionsOption = {
    'riesenie': 'R',
    'zadanie': 'Z'
}

$cppSourceVersions = $cppSourceVersionsOption.map{ |key, value| [key, '\s*//#' + value.to_s + '\s*'] }.to_h()

$cppSourceVersions.each{ |key, value|
    puts key.to_s + " -> " + value.to_s
}

# Return true if 'srcFile' contains at least one specific line, else return false
def isForkNeeded(srcFile)
    source = IO.read(srcFile)
    $cppSourceVersions.each_value{ |value|
        if source =~ /#{value}/m
            return true
        end
    }
    return false
end

# Create specific source files from input sources files
def forkCpp(srcFile, srcDir, distDir)

    # set content of all output source file to empty strings
    output = {} #content of output source files
    $cppSourceVersions.each_key { |key|
        output[key] = ""
    }

    # for each line in the input source file
    #    if the line is specific then copy it to an appropriate output source file
    #    else copy it to all output source files
    File.readlines(srcFile).each { |line|
        specific = false
        $cppSourceVersions.each{ |key, value|
            regexp = Regexp.new(value)
            if regexp.match(line)
                specific = true
                output[key] += line.sub(regexp, "\n")
            end
        }
        if specific == false
            $cppSourceVersions.each_key { |key|
                output[key] += line
            }
        end
    }

    # write content to output files
    extension = File.extname(srcFile)
    basePath = distDir + '/' + Pathname.new(srcFile).relative_path_from(Pathname.new(srcDir)).to_s.chomp(extension)
    FileUtils.mkdir_p(File.dirname(basePath)) # for a case that the subdirectory doesn't exist
    $cppSourceVersions.each { |key, value|
        destFileName = basePath + "_" + key.to_s  + extension
        puts " " + destFileName
        File.write(destFileName, output[key])
    }
end

# Create output source code files according to input source code files
def distributeCpp(srcFile, srcDir, distDir)
    puts srcFile

    if isForkNeeded(srcFile)
        forkCpp(srcFile, srcDir, distDir)
    else
        destFile = distDir + '/' + Pathname.new(srcFile).relative_path_from(Pathname.new(srcDir)).to_s()
        FileUtils.mkdir_p(File.dirname(destFile)) #for a case that the subdirectory doesn't exist
        FileUtils.cp(srcFile, destFile)
    end

end

# Checks errors (and warnings) in distributed source code files
def checkCodeError(projectDir)
    inputDir = projectDir + '/dist'
    tmpDir = projectDir + '/tmpCodeChecker'

    FileUtils.rm_rf(tmpDir)
    FileUtils.mkdir_p(tmpDir)

    Dir[inputDir + '/**/*.{c,cpp,cc,h,hpp}'].each { |inputFile|
        tmpFile = tmpDir + '/' + File.basename(inputFile)
        FileUtils.cp(inputFile, tmpFile)

        compiler = (File.extname(tmpFile) == ".c" ? "gcc -std=c11" : "g++ -std=gnu++11" ) # g++ -std=c++11 produces strange errors in standard header files
        warningFlag = (/zadanie/ =~ inputFile ? "" : "-Wall")

        command ="#{compiler} #{warningFlag} -o #{tmpDir}/a.exe #{tmpFile}"
        p command
        `#{command}`
    }

   FileUtils.rm_rf(tmpDir)
end
