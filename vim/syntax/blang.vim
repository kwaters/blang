" Vim syntax file
" Language: B (Predecessor to C)

if exists("b:current_syntax")
    finish
endif

syn region blangComment start="/\*" end="\*/"

syn region blangString start=+"+ skip=+\*"+ end=+"+ contains=blangSpecialChar
syn region blangCharacter start="'" skip="\*'" end="'" contains=blangSpecialChar
syn match blangNumber display "\<\d\+\>"

syn keyword blangStatement goto return
syn keyword blangConditional if else switch
syn keyword blangRepeat while
syn keyword blangLabel case
syn match blangLabel display "^\s*\I\i*\s*:"me=e-1

syn keyword blangStorageClass auto extrn

syn match blangSpecialChar display contained "\*."


hi def link blangComment Comment

hi def link blangString String
hi def link blangCharacter Character
hi def link blangNumber Number

hi def link blangStatement Statement
hi def link blangConditional Conditional
hi def link blangRepeat Repeat
hi def link blangLabel Label

hi def link blangStorageClass StorageClass

hi def link blangSpecialChar SpecialChar
