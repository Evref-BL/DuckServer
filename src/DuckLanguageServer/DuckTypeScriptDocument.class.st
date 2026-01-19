Class {
	#name : 'DuckTypeScriptDocument',
	#superclass : 'PLSDocument',
	#category : 'DuckLanguageServer-Document',
	#package : 'DuckLanguageServer',
	#tag : 'Document'
}

{ #category : 'instance creation' }
DuckTypeScriptDocument class >> supportDocument: aTextDocument [
	"return true if this class can host this kind of textDocument"

	^ (aTextDocument at: #languageId) = 'typescript'
]

{ #category : 'instance creation' }
DuckTypeScriptDocument class >> supportDocumentUri: aTextDocumentUri [
	"return true if this class can host this kind of textDocument"

	^ aTextDocumentUri endsWith: '.ts'
]

{ #category : 'code lens' }
DuckTypeScriptDocument >> codeLens [
	"CodeLens (short for “code lenses”) are small, contextual pieces of information displayed above or near your code, provided by the language server.
They usually show extra information (like references, test status, or version control info), and may also be clickable commands (e.g., “Run Test” or “Show References”)."

	| fast famixEntities famixRules fastRules codeLens |
	codeLens := OrderedCollection new.

	"1- get FAST model"
	fast := self getFASTModel.

	"2- make sure we have a famixModel, if no generate it"
	self createNewFamixTypeScriptModel.

	"3- Resolve FAST entities that are supposed to be on top and update the famix model"
	famixEntities := self resolveFamixEntitiesFrom: fast.

	"I am not sure yet how the below 2 steps should be handled"
	
	MiApplication current buses do: [ :bus |
		bus globallySelect: famixEntities first ].

	"b- update the famxentity based on the new fast"

	self
		updateModelFromDocument: self
		relativeToFamixEntity: famixEntities first
		withCorrespondingFast: fast.

	"famixEntities do: [ :eachFamixEntity | ""a- get the famixEntity""
		MiApplication current buses do: [ :bus |
			bus globallySelect: eachFamixEntity ].

		""b- update the famxentity based on the new fast""
		self
			updateModelFromDocument: self
			relativeToFamixEntity: eachFamixEntity
			withCorrespondingFast: fast ]."

	"4- Get famixRules grouped by the entities"
	famixRules := self collectRulesFor: FamixTypeScriptRules.

	"5- Execute famixRules over famixModel"
	codeLens := self
		            collectCodeLensFor: famixRules
		            using: self mooseModel.

	"6- Get fastRules grouped by the entities"
	fastRules := self collectRulesFor: FASTTypeScriptRules.

	"7- Execute fastRules over fastModel"
	codeLens addAll: (self collectCodeLensFor: fastRules using: fast).

	^ codeLens asArray
]

{ #category : 'model - create' }
DuckTypeScriptDocument >> createNewFamixTypeScriptModel [

	(MooseModel root select: [ :model |
		 model isKindOf: FamixTypeScriptModel ]) ifEmpty: [
		MooseModel root add:
			(FamixTypeScriptModel new name: 'typeScriptModel') ]
]

{ #category : 'diagnostics' }
DuckTypeScriptDocument >> diagnostics [
	"Diagnostics are messages sent by the language server to the editor (client) to report problems or warnings in your code.
They correspond to the squiggly underlines (red, yellow, or blue) you see in your IDE — for errors, warnings, or hints."

	| fast diagnostics newFamixEntity famixEntities |
	"1- Parse the document and get FASTTypeScript"
	fast := self getFASTModel.

	"2- make sure we have a famixModel, if no generate it"
	self createNewFamixTypeScriptModel.


	"3- Resolve FAST entities that are supposed to be on top"
	famixEntities := self resolveFamixEntitiesFrom: fast.

	"4- Loop over each entity and update the model"

	diagnostics := OrderedCollection new.

	"famixEntities do: [ :eachFamixEntity | ""a- get the famixEntity""
		MiApplication current buses do: [ :bus |
			bus globallySelect: eachFamixEntity ].

		""b- update the famxentity based on the new fast""
		newFamixEntity := self
			                  updateModelFromDocument: self
			                  relativeToFamixEntity: eachFamixEntity
			                  withCorrespondingFast: fast

		""I believe diagnostics should change""
		""c- perform diagnostics over the new famixEntity""
		""diagnostics := self
			               performDiagnosticsFor: self
			               relativeToFamixEntity: newFamixEntity.""

		""d- perform diagnostics over fast then add diagnostics to the result to be returned to the IDE""

		""diagnostics addAll:
			(self performDiagnosticsFor: self relativeToFastModel: fast)"" ]."

	^ diagnostics
]

{ #category : 'parsing' }
DuckTypeScriptDocument >> getFASTModel [
 
	^ [ FASTTypeScriptParser new parse: self text ]
		on: Error
		do: [ 
			self server log: 'Cannot parse'. 
			{} ].

	
]

{ #category : 'accessing' }
DuckTypeScriptDocument >> mooseModel [

	^ (MooseModel root select: [ :model | model isKindOf: FamixTypeScriptModel ])
		  at: 1
]

{ #category : 'diagnostics' }
DuckTypeScriptDocument >> performDiagnosticsFor: document relativeToFamixEntity: famixEntity [

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
DuckTypeScriptDocument >> performDiagnosticsFor: aDocument relativeToFastModel: aFASTModel [

	| diagnostics violations |
	diagnostics := OrderedCollection new.
	violations := self server runCriticBrowserOn: aFASTModel.
	violations do: [ :violation |
		diagnostics add:
			(self buildViolation: violation forDocument: aDocument) ].

	^ diagnostics
]

{ #category : 'resolving' }
DuckTypeScriptDocument >> resolveFamixEntitiesFrom: aFASTModel [

	| interfaces classes enums functions |
	classes := self resolveModelClassesFromAST: aFASTModel.
	interfaces := self resolveModelInterfacesFromAST: aFASTModel.
	enums := self resolveModelEnumsFromAST: aFASTModel .
	functions := self resolveModelFunctionsFromAST: aFASTModel .

	^ classes , interfaces , enums , functions
]

{ #category : 'diagnostics' }
DuckTypeScriptDocument >> resolveModelClassFromAST: fastModel [
	| mainClassName | 
	mainClassName := (fastModel allWithType: FASTTypeScriptClassDeclaration) anyOne name sourceCode.
	^ self mooseModel allModelClasses detect: [ :class | class name = mainClassName ] ifNone: [ nil ]
]

{ #category : 'diagnostics' }
DuckTypeScriptDocument >> resolveModelClassesFromAST: fastModel [

	| classDecls |
	classDecls := fastModel allWithType: FASTTypeScriptClassDeclaration.

	^ classDecls collect: [ :decl |
		  | className |
		  className := decl name sourceCode.
		  self mooseModel allModelClasses
			  detect: [ :famixClass | famixClass name = className ]
			  ifNone: [ nil ] ]
]

{ #category : 'diagnostics' }
DuckTypeScriptDocument >> resolveModelEnumsFromAST: fastModel [

	| decls |
	decls := fastModel allWithType: FASTTypeScriptEnumDeclaration.

	^ decls collect: [ :decl |
		  | name |
		  name := decl name sourceCode.
		  (self mooseModel allWithType: FamixTypeScriptEnum )
			  detect: [ :enum | enum name = name ]
			  ifNone: [ nil ] ]
]

{ #category : 'diagnostics' }
DuckTypeScriptDocument >> resolveModelFunctionsFromAST: fastModel [

	| decls |
	decls := fastModel allWithType: FASTTypeScriptFunctionDeclaration.

	^ decls collect: [ :decl |
		  | name |
		  name := decl name sourceCode.
		  (self mooseModel allWithType: FamixTypeScriptFunction )
			  detect: [ :function | function name = name ]
			  ifNone: [ nil ] ]
]

{ #category : 'diagnostics' }
DuckTypeScriptDocument >> resolveModelInterfacesFromAST: fastModel [

	| decls |
	decls := fastModel allWithType: FASTTypeScriptInterfaceDeclaration.

	^ decls collect: [ :decl |
		  | name |
		  name := decl name sourceCode.
		   (self mooseModel allWithType: FamixTypeScriptInterface )
			  detect: [ :famixInterface | famixInterface name = name ]
			  ifNone: [ nil ] ]
]

{ #category : 'diagnostics' }
DuckTypeScriptDocument >> updateModelFromDocument: aDocument relativeToFamixEntity: famixEntity withCorrespondingFast: fast [
	
	^ FTSMUModelUpdater new
		  famixModel: (famixEntity mooseModel ifNil: [
					   (MooseModel root select: [ :model |
							    model isKindOf: FamixTypeScriptModel ])
						   at: 1
						   ifAbsent: [ nil ] ]);
		  fastModel: fast;
		  famixEntity: famixEntity;
		  fileAnchorPath: ((aDocument uri withoutPrefix: 'file://')
				   copyReplaceAll: '%3A'
				   with: ':');
		  update
]
