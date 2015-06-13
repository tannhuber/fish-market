#!/usr/local/bin/fish
################################################################################
# File:
#   mdbook.fish
#
# Description:
#   Creates ebooks in epub and mobi format from markdown input files
#
# Maintainer:
#   Joseph Tannhuber <sepp.tannhuber@yahoo.de>
################################################################################

################################################################################
# => Create metadata
################################################################################
set date (date +%F)
if not test -e ".metadata"
    echo '# Created by mdbook.fish' > .metadata
    read -p 'echo "title: "' title
    echo -e "title\t$title" >> .metadata
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
switch $language
    case 'de'
        set toctitle "Inhaltsverzeichnis"
        set refstart "Anfang"
    case 'en'
        set toctitle "Contents"
        set refstart "Begining"
end


################################################################################
# => Calculate toc depth
################################################################################
set tmpfile (mktemp)
grep --color=never '^#[^#]' (seq 0 9)*.md > /dev/null; and set tocdepth 1
grep --color=never '^##[^#]' (seq 0 9)*.md > /dev/null; and set tocdepth 2
grep --color=never '^###[^#]' (seq 0 9)*.md > /dev/null; and set tocdepth 3
grep --color=never '^####[^#]' (seq 0 9)*.md > /dev/null; and set tocdepth 4
for file in (seq 0 9)*.md
    grep -H --color=never '^#' $file \
    | sed -e 's|\.md:|\\t|' -e 's|####|4\\t|' -e 's|###|3\\t|' -e 's|##|2\\t|' -e 's|#|1\\t|' >> $tmpfile
end
set contentfiles (cut -f1 $tmpfile)
set sectiondepths (cut -f2 $tmpfile)
set sections (cut -f3 $tmpfile | sed 's|^[[:space:]]*||')
set references (seq (count $sections))
rm $tmpfile

################################################################################
# => Create directory tree
################################################################################
test -d "build/OEBPS/content/"; and rm -rf "build/OEBPS/content/"
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
        if ($0!~"#" && $0 && parstatus==0) {print "<p>"$0; parstatus=2} \
        if ($0!~"#" && $0 && parstatus==1) {print "<p class=\"texttop\">"$0; parstatus=2} \
        if (!$0 && parstatus==2) {print "</p>\n"; parstatus=0}} \
        END{if (parstatus==2) print "</p>"}' $mdfile \
    | awk -v id=$id '/^#/{sub(/^####[[:space:]]*/,"<h4 id=\"ref"id"\">") \
        sub(/^###[[:space:]]*/,"<h3 id=\"ref"id"\">") \
        sub(/^##[[:space:]]*/,"<h2 id=\"ref"id"\">") \
        sub(/^#[[:space:]]*/,"<h1 id=\"ref"id"\">") id++}1' \
    | sed -re 's|^<h([1234])(.*)|<h\1\2</h\1>|' \
    -e 's|»|<span class="i">»|g' \
    -e 's|«|«</span>|g' \
    -e 's|\~\~([^~]*)\~\~|<span class="st">\1</span>|g' \
    -e 's|\~([^~]*)\~|<span class="u">\1</span>|g' \
    -e 's|[*_][*_]([^*_]*)[*_][*_]|<span class="b">\1</span>|g' \
    -e 's|[*_]([^*_]*)[*_]|<span class="i">\1</span>|g' >> $htmlfile
    echo '</body>
    </html>' >> $htmlfile
    sed -i 's|^[[:space:]]*||' $htmlfile
end

#    -e 's|\([*_][*_][^*_]*\)[*_]\([^*_]*\)[*_]\([^*_]*[*_][*_]\)|\1<span class="ib">\2</span>\3|g' \
#    -e 's|\([*_][^*_]*\)[*_][*_]\([^*_]*\)[*_][*_]\([^*_]*[*_]\)|\1<span class="ib">\2</span>\3|g' \
#    -e 's|\([*_][*_][^*_]*\)[~]\([^*_]*\)[~]\([^*_]*[*_][*_]\)|\1<span class="bu">\2</span>\3|g' \
#    -e 's|\([~][^*_]*\)[*_][*_]\([^*_]*\)[*_][*_]\([^*_]*[~]\)|\1<span class="bu">\2</span>\3|g' \
#    -e 's|\([*_][^*_]*\)[~]\([^*_]*\)[~]\([^*_]*[*_]\)|\1<span class="iu">\2</span>\3|g' \
#    -e 's|\([~][^*_]*\)[*_]\([^*_]*\)[*_]\([^*_]*[~]\)|\1<span class="iu">\2</span>\3|g' \

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
<dc:title>'$title'</dc:title>
<dc:language>'$language'</dc:language>
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
for font in build/OEBPS/fonts/*.otf
    set fontname (echo $font | cut -d'.' -f1)
    echo '<item href="fonts/'(basename $font)'" id="'$fontname'" media-type="font/opentype"/>' >> $contentfile
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
set beginning
for file in $contentfiles
    if test (echo $file | grep --color=never '^[1-9]')
        set beginning $file
        break
    end
end
echo '<guide>
<reference href="content/htmltoc.html" type="toc" title="'$toctitle'"/>
<reference href="content/'$beginning'.html" type="text" title="'$refstart'"/>
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
<meta content="'$tocdepth'" name="dtb:depth"/>
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
for sectionnum in (seq $numsections)
    if test $sectionnum -gt 1
        if test $sectiondepths[$sectionnum] -eq 1
            set chapter (expr $chapter + 1)
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
<h2>'$toctitle'</h2>' > $htmltocfile
set depth 0
set order 1
set chapter 1
for sectionnum in (seq $numsections)
    if expr $contentfiles[$sectionnum] : "0" > /dev/null
        continue
    end
    while test $depth -lt $sectiondepths[$sectionnum]
        set depth (expr $depth + 1)
        if test $depth -lt $sectiondepths[$sectionnum]
            set order (expr $order + 1)
        end
    end
    echo '<p class="toctext'$sectiondepths[$sectionnum]'"><a href="'$contentfiles[$sectionnum]'.html#ref'$references[$sectionnum]'">'$sections[$sectionnum]'</a></p>' >> $htmltocfile
end
# echo '<p class="toctext"><a href="content002.html#h2-1">Chapter 1 - Getting Started</a></p>
echo '</body>
</html>' >> $htmltocfile

################################################################################
# => Create stylesheet.css file if it does not exist
################################################################################
set stylesheet "build/OEBPS/css/stylesheet.css"
if not test -e $stylesheet
    echo '/* BB eBooks BoilerPlate Kindle for MOBI 7 and KF8*/
    /* Modify as Needed */
    /* visit us @ http://bbebooksthailand.com/developers.html */
    /*===Reset Code===*/
    html, body, div, applet, object, iframe, h1, h2, h3, h4, h5, h6, p, blockquote, pre, abbr, acronym, address, big, cite, code, del, dfn, em, img, ins, kbd, q, s, samp, small, strike, strong, sub, sup, tt, var, center, fieldset, form, label, legend, table, caption, tbody, tfoot, thead, article, aside, canvas, details, embed, figure, figcaption, footer, header, hgroup, menu, nav, output, ruby, section, summary, time, mark, audio, video
    {
    margin: 0;
    padding: 0;
    border: 0;
    font-size: 100%;
    vertical-align: baseline;
    }
    /* Do Not reset ol, ul, or table for MOBI 7. It blows out all styling */
    /*===GENERAL PRESENTATION===*/
    /*===Body Presentation and Margins===*/
    body
    {
    text-align: justify;
    line-height: 120%;
    }
    /*===Headings===*/
    /* After page breaks, Kindle does not render margins above the content unless there is a file split in the package. */
    h1
    {
    text-indent: 0;
    text-align: center;
    margin: 100px 0 0 0;
    font-family: sans-serif;
    font-size: 2.0em;
    font-weight: bold;
    page-break-before: always;
    }
    h2
    {
    text-indent: 0;
    text-align: center;
    margin: 50px 0 0 0;
    font-family: sans-serif;
    font-size: 1.5em;
    font-weight: bold;
    page-break-before: always;
    }
    h3
    {
    text-indent: 0;
    text-align: left;
    font-family: sans-serif;
    font-size: 1.4em;
    font-weight: bold;
    }
    h4
    {
    text-indent: 0;
    text-align: left;
    font-family: sans-serif;
    font-size: 1.2em;
    font-weight: bold;
    }
    /*===Paragraph Elements===*/
    /* Margins are usually added on the top, left, and right, but not on the bottom to prevent Kindle not collapsing white space properly */
    /*firstline indent for fiction*/
    p
    {
    text-indent: 1.25em;
    margin: 0;
    }
    /*block indent for non-fiction*/
    /*
    p
    {
    text-indent: 0;
    margin: 1.0em 0 0 0;
    }
    */
    /* for centered text and element wrappers on images*/
    p.centered
    {
    text-indent: 0;
    margin: 1.0em 0 0 0;
    text-align: center;
    }
    /* section Breaks (can use centered-style for non-fiction) */
    p.centeredbreak
    {
    text-indent: 0;
    margin: 1.0em 0 1.0em 0;
    text-align: center;
    }
    /* First sentence in chapters following heading */
    p.texttop
    {
    margin: 1.5em 0 0 0;
    text-indent: 0;
    }
    /* 1st level TOC */
    p.toctext1
    {
    margin: 0 0 0 1.5em;
    text-indent: 0;
    text-align: left;
    }
    /* 2nd level TOC */
    p.toctext2
    {
    margin: 0 0 0 2.5em;
    text-indent: 0;
    text-align: left;
    }
    /* 3rd level TOC */
    p.toctext3
    {
    margin: 0 0 0 3.5em;
    text-indent: 0;
    text-align: left;
    }
    /* 4th level TOC */
    p.toctext4
    {
    margin: 0 0 0 4.5em;
    text-indent: 0;
    text-align: left;
    }
    /*==IMAGES==*/
    /*===IN-LINE STYLES===*/
    span.i
    {
    font-style: italic;
    }
    span.b
    {
    font-weight: bold;
    }
    span.u
    {
    text-decoration: underline;
    }
    span.st
    {
    text-decoration: line-through;
    }
    /*==in-line combinations==*/
    /* Using something like <span class="i b">... may seem okay, but it causes problems on the Kindle */
    span.ib
    {
    font-style: italic;
    font-weight: bold;
    }
    span.iu
    {
    font-style: italic;
    text-decoration: underline;
    }
    span.bu
    {
    font-weight: bold;
    text-decoration: underline;
    }
    span.ibu
    {
    font-style: italic;
    font-weight: bold;
    text-decoration: underline;
    }
    /* Superscripted Footnote Text */
    .footnote
    {
    vertical-align: super;
    font-size: 0.75em;
    text-decoration: none;
    }
    /*==KF8 specific here ==*/
    @media amzn-kf8{
    span.dropcap {
    font-size: 300%;
    font-weight: bold;
    height: 1em;
    float: left;
    margin: -0.2em 0.1em 0 0.1em;
    }
    p.clearit
    {
    clear: both;
    }
    ol, ul, li, dl, dt, dd
    {
    margin: 0;
    padding: 0;
    border: 0;
    font-size: 100%;
    vertical-align: baseline;
    }
    /*==Lists ==*/
    ul
    {
    margin: 1em 0 0 2em;
    text-align: left;
    }
    ol
    {
    margin: 1em 0 0 2em;
    text-align: left;
    }
    table
    {
    border-collapse: collapse;
    border-spacing: 0;
    margin: 1.0em auto;
    }
    tr, th, td
    {
    margin: 0;
    padding: 2px;
    border: 1px solid black;
    font-size: 100%;
    vertical-align: baseline;
    }
    } /* End KF8 Specific Styles */
    /*==e-ink Kindle Specific==*/
    @media amzn-mobi{
    /* pseudo dropcaps for e-ink Kindles */
    span.dropcap {
    font-size: 1.5em;
    font-weight: bold;
    }
    } /* End e-ink Kindle Specific Styles */
    /*==eBook Specific Formatting Below Here==*/' > $stylesheet
    sed -i 's|^[[:space:]]*||' $stylesheet
end

################################################################################
# => Copy cover.jpg
################################################################################
set coverimage "build/OEBPS/images/cover.jpg"
if not test -e $coverimage
    cp cover.jpg $coverimage
end

################################################################################
# => Create epub file
################################################################################
cd build
set epubfile (echo $title | sed 's|[[:space:]]|_|g')".epub"
set mobifile (echo $title | sed 's|[[:space:]]|_|g')".mobi"
if test -e $epubfile
    rm $epubfile
end
if test -e $mobifile
    rm $mobifile
end
zip -0Xq $epubfile mimetype
zip -Xr9Dq $epubfile *
epubcheck $epubfile

################################################################################
# => Create mobi file if kindlegen is detected
################################################################################
if type kindlegen
    kindlegen -c1 $epubfile
end
