TERMUX_SUBPKG_DESCRIPTION="Texlive's collection-pictures"
TERMUX_SUBPKG_DEPENDS="texlive-latexextra"
TERMUX_SUBPKG_INCLUDE=$(python3 $TERMUX_SCRIPTDIR/packages/texlive/parse_tlpdb.py pictures $TERMUX_PKG_TMPDIR/texlive.tlpdb)
TERMUX_SUBPKG_CONFLICTS="texlive-bin (<< 20190410), texlive (<< 20190410)"
