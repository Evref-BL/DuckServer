Class {
	#name : 'DuckRule',
	#superclass : 'Object',
	#instVars : [
		'name',
		'condition',
		'entityType',
		'codeLens',
		'diagnostic'
	],
	#category : 'DuckLanguageServer-Rules',
	#package : 'DuckLanguageServer-Rules'
}

{ #category : 'accessing' }
DuckRule >> codeLens [

	^ codeLens
]

{ #category : 'accessing' }
DuckRule >> codeLens: anObject [

	codeLens := anObject
]

{ #category : 'accessing' }
DuckRule >> condition [

	^ condition
]

{ #category : 'accessing' }
DuckRule >> condition: anObject [

	condition := anObject
]

{ #category : 'accessing' }
DuckRule >> diagnostic [

	^ diagnostic
]

{ #category : 'accessing' }
DuckRule >> diagnostic: anObject [

	diagnostic := anObject
]

{ #category : 'accessing' }
DuckRule >> entityType [

	^ entityType
]

{ #category : 'accessing' }
DuckRule >> entityType: anObject [

	entityType := anObject
]

{ #category : 'accessing' }
DuckRule >> name [

	^ name
]

{ #category : 'accessing' }
DuckRule >> name: anObject [

	name := anObject
]
