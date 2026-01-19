Class {
	#name : 'DuckLanguageServer',
	#superclass : 'PLSAbstractServer',
	#instVars : [
		'criticBrowser',
		'criticsPath'
	],
	#category : 'DuckLanguageServer',
	#package : 'DuckLanguageServer'
}

{ #category : 'lsp - code action' }
DuckLanguageServer >> buildCodeActionShowDescriptionFor: diagnostic [

	^ (PLSCodeAction new
		   title: 'Description: ', (diagnostic at: #message);
		   kind: PLSCodeActionKind quickfix;
		   command: (PLSCommand new
				    title: 'Description: ', (diagnostic at: #message);
				    command: 'blps.showCodingRuleDescription';
				    arguments: { (diagnostic
						     at: #data
						     ifAbsent: [ 
							     'blRules:///' , (diagnostic
								     at: #code
								     ifAbsent: [ '' ]) printString , '.md' ]) };
				    yourself) yourself) asJRPCJSON
]

{ #category : 'lsp - code action' }
DuckLanguageServer >> codeActionForDocument: textDocument atRange: range withContext: context [

	<jrpc: #'textDocument/codeAction'>
	| actions diagnostics |
	actions := OrderedCollection new.
	diagnostics := context at: #diagnostics.
	"BL Language server diagnostics"
	actions addAll: ((diagnostics select: [ :diagnostic |
			  (diagnostic includesKey: #source) and: [
				  (diagnostic at: #source) = self serverName ] ]) flatCollect: [
			 :diagnostic |
			 { (self buildCodeActionShowDescriptionFor: diagnostic) } ]).
	"Generic diagnostics"
	actions addAll: ((diagnostics select: [ :diagnostic |
			  (diagnostic includesKey: #source) not or: [
				  (diagnostic at: #source) ~= self serverName ] ]) collect: [
			 :diagnostic |
			 self genericCodeActionFor: diagnostic on: textDocument ]).

	^ actions asArray
]

{ #category : 'duck - version' }
DuckLanguageServer >> commandPharoLanguageServerVersion [

	<jrpc: #'duck:version'>
	^ '0.0.0'
]

{ #category : 'accessing' }
DuckLanguageServer >> criticBrowser [

	^ criticBrowser
]

{ #category : 'accessing' }
DuckLanguageServer >> criticBrowser: anObject [

	criticBrowser := anObject
]

{ #category : 'accessing' }
DuckLanguageServer >> criticsPath [

	^ criticsPath
]

{ #category : 'accessing' }
DuckLanguageServer >> criticsPath: anObject [

	criticsPath := anObject
]

{ #category : 'lsp - text synchronisation' }
DuckLanguageServer >> didChange: textDocument contentChanges: contentChanges [

	<jrpc: #'textDocument/didChange'>
	| document |
	document := self context
		            textItem: (textDocument at: #uri)
		            ifAbsent: [
			            self didOpen: textDocument.
			            textDocument ].
	document version: (textDocument at: #version).
	document text: (contentChanges anyOne at: #text).
	self context clientContext capabilities textDocument diagnostic
		ifNil: [ self sendDiagnosticsforDocument: document ]
]

{ #category : 'lsp - text synchronisation' }
DuckLanguageServer >> didClose: textDocument [

	<jrpc: #'textDocument/didClose'>
	| document |
	document := self context removeItem: (textDocument at: #uri).

	"reset diagnostics "
	self
		sendData: (self convertJRPCJsonableObjectToJSON:
				 ((JRPCNotificationObject method:
					   'textDocument/publishDiagnostics') params:
					  (PLSPublishDiagnosticsParams new
						   diagnostics: {  };
						   uri: document uri;
						   version: document version;
						   yourself)) asJRPCJSON)
		toClient: clientOutStream
]

{ #category : 'lsp - text synchronisation' }
DuckLanguageServer >> didOpen: textDocument [

	<jrpc: #'textDocument/didOpen'>
	| document |

	document := self context
		            textItem: (textDocument at: #uri)
		            put: (PLSDocument from: textDocument).
	document server: self
	"self onDocumentChange: document"
]

{ #category : 'lsp - text synchronisation' }
DuckLanguageServer >> didSave: textDocument text: text [
	<jrpc: #'textDocument/didSave'>
]

{ #category : 'duck - graph view' }
DuckLanguageServer >> duckGraphViewForTextDocument: textDocument atPosition: position [

	<jrpc: #'duck:graph-view'>
	| internalTextDocument data |
	internalTextDocument := self context textItem:
		                        (textDocument at: #uri at: #external).

	data := DuckGraphDataBuilder new
		        entity: internalTextDocument;
		        buildData.
	^ data asJRPCJSON
]

{ #category : 'duck - tools' }
DuckLanguageServer >> duckOpenTool: id [

	<jrpc: #'duck:openTool'>
	(self class environment at: id asSymbol) open.
	^ 'tool opened'
]

{ #category : 'duck - tools' }
DuckLanguageServer >> duckTools [

	<jrpc: #'duck:dashTools'>
	^ (MiAbstractBrowser allSubclasses
		   reject: #isAbstract
		   thenCollect: [ :class |
			   DuckTool new
				   name: class menuLabel;
				   id: class name;
				   isDirectory: false;
				   yourself ]) asArray
]

{ #category : 'duck - rules' }
DuckLanguageServer >> duckUpdateRules: rulesFilePath [

	<jrpc: #'duck:updateRules'>
	self criticsPath: rulesFilePath.
	self loadCriticsRule.
	^ true
]

{ #category : 'duck - rules' }
DuckLanguageServer >> duckUpdateSettingsMistral: mistralApiKey [

	<jrpc: #'duck:updateSettings'>
	(mistralApiKey isNotNil and: [ mistralApiKey isNotEmpty ]) ifTrue: [
		LLMAPI apiKey: mistralApiKey ].
	^ true
]

{ #category : 'private' }
DuckLanguageServer >> fixEncodingOf: aString [

	^ [ aString asByteArray utf8Decoded ]
		  on: ZnInvalidUTF8
		  do: [ "if cannot correct, probably it was already correct"
		  ^ aString ]
]

{ #category : 'duck - rules' }
DuckLanguageServer >> fixWithAI: rulePath ofDocument: textDocumentURI [

	<jrpc: #'duck:fixWithAI'>
	| textDocument api result id rule answer concernedStartPos concernedEndPos concernedText |
	textDocument := self context textItem: textDocumentURI.

	id := ((rulePath withoutPrefix: 'blRules:///') withoutSuffix: '.md')
		      asInteger.
	rule := self criticBrowser model ruleComponents detect: [ :aRule |
		        aRule mooseID = id ].

	concernedStartPos := rule violations anyOne violatingEntity startPos
	                     - 1.
	concernedEndPos := rule violations anyOne violatingEntity endPos.
	concernedText := textDocument text
		                 copyFrom: (concernedStartPos max: 1)
		                 to: concernedEndPos.

	api := LLMAPI chat.
	api host: 'api.mistral.ai'.

	api payload
		temperature: 0.5;
		model: 'mistral-small-latest';
		top_p: 1;
		max_tokens: 250;
		messages: {
				(LLMAPIChatObjectMessage
					 role: 'system'
					 content: 'You are a usefull code assistant').
				(LLMAPIChatObjectMessage
					 role: 'user'
					 content:
						 'Corrige le code suivant en respectant la règle: '
						 , rule summary , '
Be creative! Only give me the code without any explanation. Do not add comment in the code. Keep existing comment.

```' , concernedText , '
```') }.

	result := api performRequest.
	answer := result.
	self
		applyWorkspaceEdit: (PLSWorkspaceEdit new
				 documentChanges: { (PLSTextDocumentEdit new
						  textDocument: (PLSVersionedTextDocumentIdentifier new
								   uri: textDocument uri;
								   version: textDocument version;
								   yourself);
						  edits: { (PLSTextEdit new
								   range: (PLSRange
										    start:
											    (textDocument text toLineCharacter: concernedStartPos)
										    end:
											    (textDocument text toLineCharacter: concernedEndPos));
								   newText:
									   ((answer trim withoutPrefix: '```') withoutSuffix: '```');
								   yourself) };
						  yourself) };
				 yourself)
		withLabel: 'test'.

	^ 'success'
]

{ #category : 'duck - codelens - generate comments' }
DuckLanguageServer >> generateCommentFor: uri from: startPos to: endPos [

	<jrpc: #'duck.generateComment'>
	| textString methodString api result resultContent |
	textString := (self context textItem: uri) text.
	methodString := textString
		                copyFrom: (1 max: startPos)
		                to: (endPos min: textString size).
	api := LLMAPI chat.
	api host: 'api.mistral.ai'.

	api payload
		model: 'mistral-small-latest';
		top_p: 1;
		response_format: 'json';
		messages: {
				(LLMAPIChatObjectMessage
					 role: 'system'
					 content:
						 'You are a javadoc writter that write only javadoc text.
Answer in json format with { originalMethod, generatedComment }.').
				(LLMAPIChatObjectMessage
					 role: 'user'
					 content:
						 'Please comment the folowing method. Do not rewrite the method

' , methodString) }.

	result := api performRequest.
	resultContent := self postDealAnswer: result.

	^ {
		  (#comment -> ((NeoJSONReader fromString: resultContent)
			    at: #generatedComment
			    ifAbsent: [ resultContent ])).
		  (#position -> (textString toLineCharacter: startPos - 1)) }
		  asDictionary
]

{ #category : 'lsp - code action' }
DuckLanguageServer >> genericCodeActionFor: diagnostic on: aTextDocument [

	^ (PLSCodeAction new
		   title: 'Fix with Duck Intelligence';
		   kind: PLSCodeActionKind quickfix;
		   command: (PLSCommand new
				    title: 'Fix with Duck Intelligence';
				    command: 'blps.genericFixWithAI';
				    arguments: {
						    diagnostic.
						    (aTextDocument at: #uri) };
				    yourself) yourself) asJRPCJSON
]

{ #category : 'initialization' }
DuckLanguageServer >> initialize [

	super initialize.
	criticBrowser := MiCriticBrowser on: MiCriticBrowser newModel.
	self loadCriticsRule
]

{ #category : 'duck - initialization' }
DuckLanguageServer >> loadCriticsRule [
	"Remove all. Code found in the tests"

	[ criticBrowser model rootContext children isNotEmpty ] whileTrue: [
		criticBrowser model
			removeChild: criticBrowser model rootContext children anyOne
			fromContext: criticBrowser model rootContext ].
	(self criticsPath isNotNil and: [ self criticsPath isNotEmpty ])
		ifTrue: [
			self criticsPath do: [ :path |
				path asFileReference exists ifTrue: [
					(path asFileReference allChildrenMatching: '*.ston') do: [
						:fileRef |
						fileRef readStreamDo: [ :stream |
							criticBrowser importRulesFromStream: stream ] ] ] ] ]
]

{ #category : 'lsp - initialization' }
DuckLanguageServer >> onInitializeTrace: trace processId: processId locale: locale clientInfo: clientInfo rootPath: rootPath workspaceFolders: workspaceFolders capabilities: capabilities rootUri: rootUri [

	<jrpc: #initialize>
	| init |
	self context clientContext: (PLPInitializeParams new
			 trace: trace;
			 processId: processId;
			 locale: locale;
			 clientInfo: clientInfo;
			 rootPath: rootPath;
			 workspaceFolders: workspaceFolders;
			 capabilities: (PLPClientCapabilities from: capabilities);
			 rootUri: rootUri;
			 yourself).
	trace ifNotNil: [ self context traceValue: trace ].
	init := PLSInitializeResult new.
	init serverInfo at: #name put: self serverName.
	init serverInfo at: #version put: self commandPharoLanguageServerVersion.
	init capabilities: (PLSServerCapabilities new
			 codeLens: PLSCodeLensOptions new;
			 inlineCompletionProvider: true;
			 textDocumentSync: (PLSTextDocumentSyncOptions new
					  openClose: true;
					  willSave: false;
					  save: { (#includeText -> true) } asDictionary;
					  willSaveWaitUntil: false;
					  change: PLSTextDocumentSyncKind full;
					  yourself) asJRPCJSON;
			 codeActionProvider: (PLSCodeActionOptions new
					  codeActionKinds: {
							  PLSCodeActionKind empty.
							  PLSCodeActionKind quickfix };
					  yourself) asJRPCJSON;
			 diagnosticProvider: (PLSDiagnosticOptions new
					  identifier: 'Duck Diagnostic engine';
					  interFileDependencies: true;
					  workspaceDiagnostics: false;
					  yourself) asJRPCJSON;
			 yourself) asJRPCJSON.
	^ init
]

{ #category : 'diagnostics' }
DuckLanguageServer >> runCriticBrowserOn: famixEntity [
	"debug method
	self criticBrowser followEntity: famixEntity.
	self criticBrowser open.
	"
	"set the model and rules in the critic browser"
	self criticBrowser model setEntities: famixEntity.
	
	"run the rules on the model and propagate the result"
	self criticBrowser model run.
	
	"use the export browser to export the result"
	^ self criticBrowser model getAllViolations
]

{ #category : 'lsp - text synchronisation' }
DuckLanguageServer >> serverName [
	^ #'Duck Language Server'
]

{ #category : 'duck - rules' }
DuckLanguageServer >> showRuleDescription: rulePath [

	<jrpc: #'duck:showRuleDescription'>
	| id |
	id := (((rulePath at: #authority) withoutPrefix: '/') withoutSuffix:
		       '.md') asInteger.
	^ (self criticBrowser model ruleComponents detect: [ :rule | 
		   rule mooseID = id ]) summary
]

{ #category : 'lsp - completion' }
DuckLanguageServer >> textDocumentInlineCompletionWithContext: context position: position textDocument: textDocument [

	<jrpc: #'textDocument/inlineCompletion'>
	| internalTextDocument api userPosition result toInsertText |
	internalTextDocument := self context textItem:
		                        (textDocument at: #uri).
	userPosition := internalTextDocument text plsToPosition: position.
	userPosition := userPosition max: 1.
	api := LLMAPI fim.
	api host: 'api.mistral.ai'.

	api payload
		temperature: 0.2;
		model: 'codestral-2501';
		top_p: 1;
		stop: (String with: Character lf);
		max_tokens: 100;
		prompt: (internalTextDocument text copyFrom: 1 to: userPosition).
	userPosition = internalTextDocument text size ifFalse: [
		api payload suffix: (internalTextDocument text
				 copyFrom: userPosition
				 to: internalTextDocument text size) ].

	result := api performRequest.

	toInsertText := self postDealAnswer: result.

	self sendTelemetry:
		{ (#command -> #'blps.inlineCompletion') } asDictionary.

	^ (PLSInlineCompletionList new
		   items: { (PLSInlineCompletionItem new
				    insertText: toInsertText;
				    command: (PLSCommand new
						     title: 'Log inline completion';
						     command: 'blps.logInlineCompletion';
						     arguments: { toInsertText };
						     yourself) asJRPCJSON;
				    yourself) };
		   yourself) asJRPCJSON
]
