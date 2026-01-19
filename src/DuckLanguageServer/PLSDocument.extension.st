Extension { #name : 'PLSDocument' }

{ #category : '*DuckLanguageServer' }
PLSDocument >> buildSmaccErr: aSmaccErr forDocument: document [

	^ PLSDiagnostic new
		  source: self server serverName;
		  message: aSmaccErr messageText;
		  range: (PLSRange
				   start: (document text toLineCharacter:
							    aSmaccErr parser currentToken startPosition - 1)
				   end: (document text toLineCharacter:
							    aSmaccErr parser currentToken stopPosition))
]

{ #category : '*DuckLanguageServer' }
PLSDocument >> buildViolation: violation forDocument: document [

	^ PLSDiagnostic new
		  source: self server serverName;
		  message: violation violatedCondition name;
		  codeDescription: (PLSCodeDescription new
				   href: violation violatedCondition ref;
				   yourself);
		  code: violation violatedCondition mooseID;
		  data: violation violatedCondition ref;
		  range: (PLSRange
				   start:
				   (document text toLineCharacter:
					    violation violatingEntity startPos - 1)
				   end:
				   (document text toLineCharacter:
					    violation violatingEntity endPos))
]

{ #category : '*DuckLanguageServer' }
PLSDocument >> collectCodeLensFor: rules using: aModel [

	| codeLens |
	codeLens := OrderedCollection new.

	rules keysDo: [ :each |
		(aModel allWithType: each) do: [ :eachEnt |
			(rules at: each) do: [ :rule |
				rule codeLens ifNotNil: [
					(rule condition value: eachEnt) ifTrue: [
						codeLens add: (rule codeLens value: self value: eachEnt) ] ] ] ] ].

	^ codeLens
]

{ #category : '*DuckLanguageServer' }
PLSDocument >> collectRulesFor: entity [

	^(entity new class methods collect: [
		              :method |
		              | rule |
		              rule := entity new perform:
			                      method selector ]) groupedBy: [ :each |
		             each entityType ].
	
	
	
]
