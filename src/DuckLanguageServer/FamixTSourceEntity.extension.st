Extension { #name : 'FamixTSourceEntity' }

{ #category : '*DuckLanguageServer' }
FamixTSourceEntity >> endPos [
	^ self sourceAnchor endPos
]

{ #category : '*DuckLanguageServer' }
FamixTSourceEntity >> startPos [
	^ self sourceAnchor startPos
]
