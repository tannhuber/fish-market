# mdbook

Creates epub and mobi files from markdown input.

## Requirements

* epubcheck
* kindlegen (optional)

## How to use

* Create an empty directory for your ebook project: `mkdir your-ebook`.
* Go into new directory: `cd your-ebook`.
* Write your ebook in markdown syntax. I recommend that you use a separate file
  for each chapter. The filenames must start with a digit. The book will be
  automatically arranged by the order of your filenames. If your filenames are
  `1_first_chapter.md`, `2_second_chapter.md` and `1a_forgotten_chapter.md`,
  the forgotten chapter will be included between the first and the second chapter.
  If a filename starts with `0`, it will appear before the html table of
  contents which might be useful for a preface. Furthermore, it won't be listed
  within the html table of contents.
* Copy a cover image with file name `cover.jpg` to `your-ebook`.
* Finally, run `mdbook.fish` and follow the instructions.
* Check the output for errors. `kindlegen` is run automatically if it can be
  detected. You can find your ebook in `build/your-title.epub` and
  `build/your-title.mobi`.
* A file `.metadata` is created. If you want to change information stored
  therein, use your favourite editor or delete the file and run `mdbook.fish`
  again.
* A `stylesheet.css` file can be found in `build/OEBPS/css/`. It should be fine
  for a well designed ebook. However, you can adapt it if it doesn't satisfy
  you. `mdbook.fish` will not overwrite an existing `stylesheet.css`.
* You can make modifications to your markdown files and run `mdbook.fish` again.
* You can also copy some `otf` fonts into `build/OEBPS/fonts`. `mdbook.fish`
  will embed them into your ebook files. But you must edit the `stylesheet.css`
  by hand to determine where you want to use them. Then, run `mdbook.fish` again.

## Style options for markdown files

* Lines starting with `#`, `##`, `###` or `####` indicate a header of first,
  second, third and fourth order, respectively. You must start with a header of
  first order. Be careful and use a valid order, e.g. a section of third order is
  only allowed after a section of second or third order.
* For **bold text** use: `**bold text**` or `__bold text__`.
* For _italic text_ use: `*italic text*` or `_italic text_`.
* For underlined text use: `~underlined text~`.
* For ~~striked through text~~ use: `~~striked through text~~`.

## Thanks

I thank [BB eBooks][bbebooks] for the nice tutorial and the `stylesheet.css`
template.

## Maintainer

Joseph Tannhuber <sepp.tannhuber@yahoo.de>

[bbebooks]: http://bbebooksthailand.com/developers.html
