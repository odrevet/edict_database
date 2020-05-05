if [ -z ${1+x} ]; then
    echo "Argument required";
    exit
fi

if [[ ! $1 =~ ^(expression|kanji|)$ ]]; then
    echo "argument must be 'expression' or 'kanji'"
    exit
fi
