function extract
    if not count $argv > /dev/null
        echo "Usage: extract <file>"
        return
    end
    if not test -f $argv
        echo "$argv is not a valid file"
        return
    end

    switch $argv
    case '*.tar.bz2'
        tar xjf $argv
    case '*.tar.gz'
        tar xzf $argv
    case '*.bz2'
        bunzip2 $argv
    case '*.rar'
        rar x $argv
    case '*.gz'
        gunzip $argv
    case '*.tar'
        r xf $argv
    case '*.tbz2'
        tar xjf $argv
    case '*.tgz'
        tar xzf $argv
    case '*.zip'
        unzip $argv
    case '*.Z'
        uncompress $argv
    case '*.7z'
        7z x $argv
    case '*'
        echo "$argv cannot be extracted via extract"
    end
end
