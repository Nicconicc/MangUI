MangUIUnicode.otf is a renamed subset of Noto Sans CJK SC Bold.
Source: https://github.com/notofonts/noto-cjk
Copyright 2014-2021 Adobe (http://www.adobe.com/), with Reserved Font Name 'Source'.
Licensed under the SIL Open Font License 1.1; see NotoCJK-LICENSE.txt.
Includes all reviewed UI translations (including new Traditional Chinese characters), extended Latin, Cyrillic and all Korean syllables.

Noto Sans integration (1.0.376):
- Unmodified static Noto Sans Regular/Bold: Latin, Greek and Cyrillic.
- Unmodified static Noto Sans CJK SC/TC/KR Regular/Bold: full pan-CJK coverage
  with Simplified Chinese, Traditional Chinese and Korean regional glyph forms.
- Official download URLs, sizes and SHA-256 checksums: Noto-sources.json.
- Licenses: NotoSans-LICENSE.txt and NotoCJK-LICENSE.txt (SIL OFL 1.1).
- Automatic (client) mode uses the original Warcraft UI fonts. Explicit language
  choices use the appropriate Noto Bold face; mixed-language menus use CJK Bold.
- The font pickers offer "Noto Sans" and "Noto Sans Bold". These saved choices
  automatically resolve to the matching regional face for the selected language.
- Individual font choices and sizes are preserved; the existing global override
  also supports both Noto choices. No SharedMedia dependency is required.
- These fonts cover the addon's supported languages, not every world script.
- MangUIUnicode.otf remains available as a fallback for failed UI font loads.
