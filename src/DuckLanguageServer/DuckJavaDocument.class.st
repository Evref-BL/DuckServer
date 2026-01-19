Class {
	#name : 'DuckJavaDocument',
	#superclass : 'PLSDocument',
	#category : 'DuckLanguageServer-Document',
	#package : 'DuckLanguageServer',
	#tag : 'Document'
}

{ #category : 'as yet unclassified' }
DuckJavaDocument class >> supportDocument: aTextDocument [
	"return true if this class can host this kind of textDocument"

	^ (aTextDocument at: #languageId) = 'java'
]

{ #category : 'as yet unclassified' }
DuckJavaDocument class >> supportDocumentUri: aTextDocumentUri [
	"return true if this class can host this kind of textDocument"

	^ aTextDocumentUri endsWith: '.java'
]

{ #category : 'code lens' }
DuckJavaDocument >> codeLens [

	| fast famixEntity fastRules codeLens famixRules |
	
	codeLens := OrderedCollection new.

	"1- Get FAST Model"
	fast := self getFASTModel.

	"2- make sure we have a famix model"
	self createNewFamixJavaModel.

	"3- Resolve famix class from FAST. !!! now this is temporary until we fix it to retrieve all needed entities. Perhaps we add also one for interface ... everything that could encapsulate source code inside and be on the very top"

	famixEntity := self resolveModelClassFromAST: fast.
	MiApplication current buses do: [ :bus |
		bus globallySelect: famixEntity ].

	"4- update famix model"
	self
		updateModelFromDocument: self
		relativeToFamixEntity: famixEntity
		withCorrespondingFast: fast.

	"5- Get fastRules grouped by the entities"
	fastRules := self collectRulesFor: FASTJavaRules.

	"6- Execute fastRules over fastModel"
	codeLens := self collectCodeLensFor: fastRules using: fast.

	"7- Get famixRules grouped by the entities"
	famixRules := self collectRulesFor: FamixJavaRules.

	"8- Execute famixRules over famixModel"
	codeLens addAll:
		(self collectCodeLensFor: famixRules using: self mooseModel).

	^ codeLens asArray
]

{ #category : 'model - create' }
DuckJavaDocument >> createNewFamixJavaModel [

		(MooseModel root select: [ :model | model isKindOf: FamixJavaModel ])
		ifEmpty: [ MooseModel root add: (FamixJavaModel new name: 'javaModel')].
]

{ #category : 'diagnostics' }
DuckJavaDocument >> diagnostics [

	| fast diagnostics famixEntity newFamixEntity |
	[
	fast := JavaSmaCCProgramNodeImporterVisitor new parseCodeString:
		        self text ]
		on: Error
		do: [
			self server log: 'Cannot parse'.
			^ {  } ].
	diagnostics := OrderedCollection new.
	"self createNewFamixJavaModel.
	""MooseModel root ifEmpty: [ MooseModel root add: FamixJavaModel new ].""
	famixEntity := self resolveModelClassFromAST: fast.
	famixEntity ifNotNil: [
		MiApplication current buses do: [ :bus |
			bus globallySelect: famixEntity ] ].
	newFamixEntity := self
		                  updateModelFromDocument: self
		                  relativeToFamixEntity: famixEntity
		                  withCorrespondingFast: fast.
	diagnostics := self
		               performDiagnosticsFor: self
		               relativeToFamixEntity: newFamixEntity.

	diagnostics addAll:
		(self performDiagnosticsFor: self relativeToFastModel: fast)."
	^ diagnostics
]

{ #category : 'parsing' }
DuckJavaDocument >> getFASTModel [

	^ [ JavaSmaCCProgramNodeImporterVisitor new withComments
		        parseCodeString: self text ]
		on: Error
		do: [
			self server log: 'Cannot parse'.
			^ {  } ].
]

{ #category : 'accessing' }
DuckJavaDocument >> mooseModel [

	^ (MooseModel root select: [ :model | model isKindOf: FamixJavaModel ])
		  at: 1
]

{ #category : 'diagnostics' }
DuckJavaDocument >> performDiagnosticsFor: document relativeToFamixEntity: famixEntity [

	| diagnostics violations |
	diagnostics := OrderedCollection new.
	violations := self server runCriticBrowserOn: famixEntity.
	violations := violations select: [ :violation | 
		              ((violation violatingEntity isAssociation
			                ifTrue: [ violation violatingEntity source ]
			                ifFalse: [ violation violatingEntity ]) atScope:
			               FamixTClass) anyOne = famixEntity ].
	violations do: [ :violation | 
		diagnostics add:
			(self buildViolation: violation forDocument: document) ].

	^ diagnostics
]

{ #category : 'diagnostics' }
DuckJavaDocument >> performDiagnosticsFor: aDocument relativeToFastModel: aFASTModel [

	| diagnostics violations |
	diagnostics := OrderedCollection new.
	violations := self server runCriticBrowserOn: aFASTModel.
	violations do: [ :violation | 
		diagnostics add:
			(self buildViolation: violation forDocument: aDocument) ].

	^ diagnostics
]

{ #category : 'diagnostics' }
DuckJavaDocument >> resolveModelClassFromAST: fastModel [
	| mainClassName | 
	mainClassName := (fastModel allWithType: FASTJavaClassDeclaration) anyOne name.
	^ self mooseModel allModelClasses detect: [ :class | class name = mainClassName ] ifNone: [ nil ]
]

{ #category : 'diagnostics' }
DuckJavaDocument >> updateModelFromDocument: aDocument relativeToFamixEntity: famixEntity withCorrespondingFast: fast [

	^ FJMUModelUpdater new
		  famixModel: (famixEntity mooseModel ifNil: [ 
					   (MooseModel root select: [ :model | 
							    model isKindOf: FamixJavaModel ]) at: 1 ifAbsent: [ nil ] ]);
		  fastModel: fast;
		  famixEntity: famixEntity;
		  fileAnchorPath: ((aDocument uri withoutPrefix: 'file://')
				   copyReplaceAll: '%3A'
				   with: ':');
		  update
]
