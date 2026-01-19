Class {
	#name : 'DuckGraphDataBuilder',
	#superclass : 'Object',
	#instVars : [
		'entity'
	],
	#category : 'DuckLanguageServer',
	#package : 'DuckLanguageServer'
}

{ #category : 'as yet unclassified' }
DuckGraphDataBuilder >> buildData [

	self entity languageId = 'java' ifTrue: [ ^ self buildJavaData ].
	^ Dictionary new
		  at: #name put: 'Eve';
		  at: #children put: {
				  (Dictionary newFrom: { (#name -> 'Cain') }).
				  (Dictionary newFrom: {
							   (#name -> 'Seth').
							   (#children -> {
									    (Dictionary newFrom: { (#name -> 'Enos') }).
									    (Dictionary newFrom: { (#name -> 'Noam') }) } asArray) }) }
				  asArray;
		  yourself
]

{ #category : 'as yet unclassified' }
DuckGraphDataBuilder >> buildJavaData [

	| fast dic root |
	[
	fast := JavaSmaCCProgramNodeImporterVisitor new withComments
		        parseCodeString: entity text ]
		on: Error
		do: [
			^ {  } ].
	dic := Dictionary new.
	root := fast rootEntities last.
	self fillDic: dic from: root.
	^ dic
]

{ #category : 'accessing' }
DuckGraphDataBuilder >> entity [

	^ entity
]

{ #category : 'accessing' }
DuckGraphDataBuilder >> entity: anObject [

	entity := anObject
]

{ #category : 'private' }
DuckGraphDataBuilder >> fillDic: aCollection from: aFASTJavaClassDeclaration [ 
|childrenDictionnary|
	aCollection at: #name put: aFASTJavaClassDeclaration name.
	childrenDictionnary := aFASTJavaClassDeclaration children collect: [ :child | self fillDic: Dictionary new from: child ].
	aCollection at: #children put: childrenDictionnary asArray.
	^ aCollection 
]
