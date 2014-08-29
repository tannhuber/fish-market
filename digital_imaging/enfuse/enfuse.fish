#!/usr/local/bin/fish
################################################################################
# File:
#   enfuse.fish
#
# Description:
#   Converts raw images with different exposures using ufraw-batch and combines
#   them with enfuse. Resulting image is in tiff format.
#
# Maintainer:
#   Joseph Tannhuber <sepp.tannhuber@yahoo.de>
################################################################################

function save_tiff -d "Convert raw image to tiff image with given exposure."
    set -l INFILE $argv[1]
    set -l EXPOSURE $argv[2]
    set -l OUTFILE $FILENAME"_"$EXPOSURE".tiff"
    if not test -f $OUTFILE
        ufraw-batch --wb=camera --base-curve=camera --exposure=$EXPOSURE \
                    --out-type=tiff --out-depth=8 --output=$OUTFILE $INFILE
    end
    set -g FILELIST $FILELIST $OUTFILE
end

if test -z $argv[1]
    echo "Please specify filename"
    exit 1
end

if not test -f $argv[1]
    echo "Invalid filename: "(set_color $fish_color_error)$argv[1]
    exit 2
end

# remove suffix from filename
set -g FILENAME (basename $argv[1] | sed 's|\.\([^\/\.]*$\)||')

# set lower exposure limit, defaults to -3
if test -n $argv[2]
    set -g lower_limit $argv[2]
else
    set -g lower_limit "-3"
end

# set upper exposure limit, defaults to 3
if test -n $argv[3]
    set -g upper_limit $argv[3]
else
    set -g upper_limit "3"
end

# check whether lower exposure limit is less than upper limit
if test $upper_limit -le $lower_limit
    echo "Upper limit "(set_color $fish_color_error)$upper_limit(set_color $fish_color_normal)" must be greater than lower limit "(set_color $fish_color_error)$lower_limit
    exit 3
end

echo "Processing from "(set_color $fish_color_param)$lower_limit(set_color $fish_color_normal)" to "(set_color $fish_color_param)$upper_limit(set_color $fish_color_normal)"..."

for i in (seq $lower_limit $upper_limit)
    save_tiff $argv[1] $i
end

# combine images with enfuse
set -e argv[(seq 3)]
enfuse $FILELIST -o $FILENAME"_enfused.tiff" $argv

echo "Done: enfused file is "$FILENAME"_enfused.tiff"
exit 0
