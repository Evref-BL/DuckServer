Class {
	#name : 'DuckTool',
	#superclass : 'Object',
	#instVars : [
		'name',
		'id',
		'isDirectory'
	],
	#category : 'DuckLanguageServer',
	#package : 'DuckLanguageServer'
}

{ #category : 'accessing' }
DuckTool >> asJRPCJSON [

	| dictionary |
	dictionary := {
		              (#id -> self id asJRPCJSON).
		              (#isDirectory -> self isDirectory asJRPCJSON).
		              (#name -> self name asJRPCJSON) } asDictionary.

	^ dictionary
]

{ #category : 'accessing' }
DuckTool >> id [

	^ id
]

{ #category : 'accessing' }
DuckTool >> id: anObject [

	id := anObject
]

{ #category : 'accessing' }
DuckTool >> isDirectory [

	^ isDirectory
]

{ #category : 'accessing' }
DuckTool >> isDirectory: anObject [

	isDirectory := anObject
]

{ #category : 'accessing' }
DuckTool >> name [

	^ name
]

{ #category : 'accessing' }
DuckTool >> name: anObject [

	name := anObject
]
