Extension { #name : 'FamixCBCondition' }

{ #category : '*DuckLanguageServer' }
FamixCBCondition >> ref [
	^ 'blRules://', self mooseID printString, '.md'
]
