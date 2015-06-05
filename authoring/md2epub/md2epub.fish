#!/usr/local/bin/fish
################################################################################
# File:
#   md2epub.fish
#
# Description:
#   Creates ebooks in epub format from markdown input files
#
# Maintainer:
#   Joseph Tannhuber <sepp.tannhuber@yahoo.de>
################################################################################

################################################################################
# => Create metadata
################################################################################
set date (date +%F)
if not test -e ".metadata"
    read -p 'echo "title: "' title
    echo -e "title\t$title" > .metadata
    read -p 'echo "author: "' author
    echo -e "author\t$author" >> .metadata
    read -p 'echo "publisher: "' publisher
    echo -e "publisher\t$publisher" >> .metadata
    read -p 'echo "language: "' language
    echo -e "language\t$language" >> .metadata
    read -p 'echo "description: "' description
    echo -e "description\t$description" >> .metadata
    while true
        read -p 'echo "keywords: "' keyword
        if test -z $keyword
            break
        end
        set keywords $keywords $keyword
    end
    echo -e "keywords\t$description" >> .metadata
    read -p 'echo "copyrights: "' copyrights
    echo -e "copyrights\t$copyrights" >> .metadata
    set uuid (uuidgen)
    echo -e "uuid\t$uuid" >> .metadata
else
    set title (grep --color=never '^title' .metadata | cut -f2)
    set author (grep --color=never '^author' .metadata | cut -f2)
    set publisher (grep --color=never '^publisher' .metadata | cut -f2)
    set language (grep --color=never '^language' .metadata | cut -f2)
    set description (grep --color=never '^description' .metadata | cut -f2)
    set keywords (grep --color=never '^keywords' .metadata | cut -f2)
    set copyrights (grep --color=never '^copyrights' .metadata | cut -f2)
    set uuid (grep --color=never '^uuid' .metadata | cut -f2)
end

################################################################################
# => Calculate toc depth
################################################################################
set tmpfile1 (mktemp)
set tmpfile2 (mktemp)
grep --color=never '^#[^#]' (seq 0 9)*.md > $tmpfile1; and set uppertocdepth 1
grep --color=never '^##[^#]' (seq 0 9)*.md >> $tmpfile1; and set uppertocdepth 2
grep --color=never '^###[^#]' (seq 0 9)*.md >> $tmpfile1; and set uppertocdepth 3
grep --color=never '^####[^#]' (seq 0 9)*.md >> $tmpfile1; and set uppertocdepth 4
grep --color=never '^####[^#]' (seq 0 9)*.md > /dev/null; and set lowertocdepth 4
grep --color=never '^###[^#]' (seq 0 9)*.md > /dev/null; and set lowertocdepth 3
grep --color=never '^##[^#]' (seq 0 9)*.md > /dev/null; and set lowertocdepth 2
grep --color=never '^#[^#]' (seq 0 9)*.md > /dev/null; and set lowertocdepth 1
sed -i -e 's|\.md:|\\t|' -e 's|####|4\\t|' -e 's|###|3\\t|' -e 's|##|2\\t|' -e 's|#|1\\t|' $tmpfile1
sort $tmpfile1 | nl -n ln > $tmpfile2
rm $tmpfile1
set references (cut -f1 $tmpfile2 | sed 's/[[:space:]]*$//' )
set contentfiles (cut -f2 $tmpfile2)
set sectiondepths (cut -f3 $tmpfile2)
set sections (cut -f4 $tmpfile2 | sed 's|^[[:space:]]*||')
rm $tmpfile2

################################################################################
# => Create directory tree
################################################################################
for directory in META-INF OEBPS/content OEBPS/images OEBPS/css OEBPS/fonts
    test -d "build/$directory"
    or mkdir -p "build/$directory"
end

################################################################################
# => Create html content files
################################################################################
for mdfile in (seq 0 9)*.md
    set htmlfile "build/OEBPS/content/"(echo $mdfile | cut -d'.' -f1)".html"
    set id $references[(contains -i (echo $mdfile | cut -d'.' -f1) $contentfiles)]
    echo '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
    <head>
    <meta http-equiv="Content-Type" content="application/xhtml+xml; charset=utf-8"/>
    <link type="text/css" rel="stylesheet" href="../css/stylesheet.css"/>
    <title>'$title'</title>
    </head>
    <body>' > $htmlfile
    sed -e 's|^[[:space:]]*$|^$|' $mdfile | \
    awk 'BEGIN{ORS=""} \
        {if ($0~"#" && parstatus!=2) {print $0"\n"; parstatus=1} \
        if ($0~"#" && parstatus==2) {print "</p>\n"$0"\n"; parstatus=1} \
        if ($0!~"#" && $0 && parstatus==2) print "\n"$0; \
        if ($0!~"#" && $0 && parstatus==1) {print "<p>"$0; parstatus=2} \
        if (!$0 && parstatus==2) {print "</p>\n"; parstatus=1}} \
        END{if (parstatus==2) print "</p>"}' $mdfile \
    | awk -v id=$id '/^#/{sub(/^####[[:space:]]*/,"<h4 id=\"ref"id"\">") \
        sub(/^###[[:space:]]*/,"<h3 id=\"ref"id"\">") \
        sub(/^##[[:space:]]*/,"<h2 id=\"ref"id"\">") \
        sub(/^#[[:space:]]*/,"<h1 id=\"ref"id"\">") id++}1' \
    | sed -e 's|^<h\([1234]\)\(.*\)|<h\1\2</h\1>|' \
    -e 's|\*\*\([^*]*\)\*\*|<strong>\1</strong>|g' \
    -e 's|\*\([^*]*\)\*|<em>\1</em>|g' \
    -e 's|__\([^_]*\)__|<strong>\1</strong>|g' \
    -e 's|_\([^_]*\)_|<em>\1</em>|g' >> $htmlfile
    echo '</body>
    </html>' >> $htmlfile
    sed -i 's|^[[:space:]]*||' $htmlfile
end

################################################################################
# => Create mimetype file
################################################################################
echo -n "application/epub+zip" > build/mimetype

################################################################################
# => Create container.xml file
################################################################################
set containerfile "build/META-INF/container.xml"
echo '<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
<rootfiles>
<rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
</rootfiles>
</container>' > $containerfile
################################################################################
# => Create content.opf file
################################################################################
set contentfile "build/OEBPS/content.opf"
echo '<?xml version="1.0" encoding="utf-8"?>
<package version="2.0" xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookId">' > $contentfile
# Write metadata section
echo '<metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">
<dc:title>$title</dc:title>
<dc:language>$language</dc:language>
<dc:identifier id="BookId" opf:scheme="uuid">urn:uuid:'$uuid'</dc:identifier>
<dc:creator opf:role="aut">'$author'</dc:creator>
<dc:publisher>'$publisher'</dc:publisher>
<dc:date>'$date'</dc:date>
<dc:description>'$description'</dc:description>' >> $contentfile
for keyword in $keywords
    echo '<dc:subject>'$keyword'</dc:subject>' >> $contentfile
end
echo '<dc:rights>'$copyrights'</dc:rights>
<meta name="cover" content="My_Cover_ID"/>
</metadata>' >> $contentfile
# Write manifest section
echo '<manifest>
<item href="images/cover.jpg" id="My_Cover_ID" media-type="image/jpeg"/>
<item href="toc.ncx" id="ncx" media-type="application/x-dtbncx+xml"/>
<item href="content/htmltoc.html" id="htmltoc" media-type="application/xhtml+xml"/>' >> $contentfile
for content in build/OEBPS/content/(seq 0 9)*
    echo '<item href="content/'(basename $content)'" id="htmlcontent'(basename $content | cut -d'.' -f1)'" media-type="application/xhtml+xml"/>' >> $contentfile
end
echo '<item href="css/stylesheet.css" id="cssstylesheet" media-type="text/css"/>' >> $contentfile
for font in build/OEBPS/fonts/*
    echo '<item href="fonts/'(basename $font)'" id="font1" media-type="font/opentype"/>' >> $contentfile
end
echo '</manifest>' >> $contentfile
# Write spine section
echo '<spine toc="ncx">' >> $contentfile
for content in build/OEBPS/content/0*
    echo '<itemref idref="htmlcontent'(basename $content | cut -d'.' -f1)'"/>' >> $contentfile
end
echo '<itemref idref="htmltoc"/>' >> $contentfile
for content in build/OEBPS/content/(seq 9)*
    echo '<itemref idref="htmlcontent'(basename $content | cut -d'.' -f1)'"/>' >> $contentfile
end
echo '</spine>' >> $contentfile
# Write guide section
echo '<guide>
<reference href="content/htmltoc.html" type="toc" title="Inhaltsverzeichnis"/>
</guide>
</package>' >> $contentfile

################################################################################
# => Create toc.ncx file
################################################################################
set tocfile "build/OEBPS/toc.ncx"
echo '<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE ncx PUBLIC "-//NISO//DTD ncx 2005-1//EN" "http://www.daisy.org/z3986/2005/ncx-2005-1.dtd">
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1" xml:lang="en">' > $tocfile
# Write metadata Section
echo '<head>
<meta content="urn:uuid:'$uuid'" name="dtb:uid"/>
<meta content="'$uppertocdepth'" name="dtb:depth"/>
<meta content="0" name="dtb:totalPageCount"/>
<meta content="0" name="dtb:maxPageNumber"/>
</head>' >> $tocfile
# Write title and author section
echo '<docTitle>
<text>'$title'</text>
</docTitle>
<docAuthor>
<text>'$author'</text>
</docAuthor>' >> $tocfile
# Write navigation map section
set numsections (count $sections)
echo '<navMap>' >> $tocfile
set depth 0
set order 1
set chapter 1
set section 0
set subsection 0
set subsubsection 0
for sectionnum in (seq $numsections)
    if test $sectionnum -gt 1
        switch $sectiondepths[$sectionnum]
            case 1
                set chapter (expr $chapter + 1)
                set section 0
                set subsection 0
                set subsubsection 0
            case 2
                set section (expr $section + 1)
                set subsection 0
                set subsubsection 0
            case 3
                set subsection (expr $subsection + 1)
                set subsubsection 0
            case 4
                set subsubsection (expr $subsubsection + 1)
        end
    end
    while test $depth -lt $sectiondepths[$sectionnum]
        set depth (expr $depth + 1)
        if test $depth -lt $sectiondepths[$sectionnum]
            echo '<navPoint id="ncxsection'$sectionnum'" playOrder="'$order'">' >> $tocfile
            set order (expr $order + 1)
        end
    end
    echo '<navPoint id="ncxsection'$sectionnum'" playOrder="'$order'">' >> $tocfile
    set order (expr $order + 1)
    echo '<navLabel>
    <text>'$sections[$sectionnum]'</text>
    </navLabel>' >> $tocfile
    set reference "#ref$references[$sectionnum]"
    echo '<content src="content/'$contentfiles[$sectionnum]'.html'$reference'"/>' >> $tocfile
    if test $sectionnum -lt $numsections
        set nextsectiondepth $sectiondepths[(expr $sectionnum + 1)]
        while test $depth -ge $nextsectiondepth
            echo '</navPoint>' >> $tocfile
            set depth (expr $depth - 1)
        end
    else
        echo '</navPoint>' >> $tocfile
    end
end
while test $depth -gt $sectiondepths[(expr $sectionnum + 1)]
    set depth (expr $depth - 1)
    echo '</navPoint>' >> $tocfile
end
echo '</navMap>
</ncx>' >> $tocfile
sed -i 's|^[[:space:]]*||' $tocfile

################################################################################
# => Create htmltoc.html file
################################################################################
set htmltocfile "build/OEBPS/content/htmltoc.html"
echo '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
<meta http-equiv="Content-Type" content="application/xhtml+xml; charset=utf-8"/>
<link type="text/css" rel="stylesheet" href="../css/stylesheet.css"/>
<title>'$title'</title>
</head>
<body>
<h2>Inhaltsverzeichnis</h2>' > $htmltocfile
set depth 0
set order 1
set chapter 1
set section 0
set subsection 0
set subsubsection 0
for sectionnum in (seq $numsections)
    while test $depth -lt $sectiondepths[$sectionnum]
        set depth (expr $depth + 1)
        if test $depth -lt $sectiondepths[$sectionnum]
            echo '<navPoint id="NCX_Chapter'$chapter'" playOrder="'$order'">' >> $tocfile
            set order (expr $order + 1)
        end
    end
    echo '<p class="toctext"><a href="'$contentfiles[$sectionnum]'.html">'$sections[$sectionnum]'</a></p>' >> $htmltocfile
end
# echo '<p class="toctext"><a href="content002.html#h2-1">Chapter 1 - Getting Started</a></p>
echo '</body>
</html>' >> $htmltocfile
