# clipd 

clipboard manager

## Requirements

* dmenu (with xft patch; on a debian based system you can run
  `update-alternatives --config dmenu`)
* xsel

## How to use

* Start daemon with `clipd`. Put it in your startup file, e.g. `.xsession`.
* Mark selection with mouse.
* Show menu with `clipd menu` in order to make selection from clipboard history.
  You probably want to create a shortcut for this.
* Paste selection with third mouse button.

## Maintainer

Joseph Tannhuber <sepp.tannhuber@yahoo.de>
