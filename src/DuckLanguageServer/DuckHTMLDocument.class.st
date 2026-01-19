Class {
	#name : 'DuckHTMLDocument',
	#superclass : 'PLSDocument',
	#category : 'DuckLanguageServer-Document',
	#package : 'DuckLanguageServer',
	#tag : 'Document'
}

{ #category : 'as yet unclassified' }
DuckHTMLDocument class >> supportDocument: aTextDocument [
	"return true if this class can host this kind of textDocument"

	^ (aTextDocument at: #languageId) = 'html'
]

{ #category : 'as yet unclassified' }
DuckHTMLDocument class >> supportDocumentUri: aTextDocumentUri [
	"return true if this class can host this kind of textDocument"

	^ aTextDocumentUri endsWith: '.html'
]

{ #category : 'diagnostics' }
DuckHTMLDocument >> diagnostics [
	"done somewhere else"


	| diagnostics importer violations |
	diagnostics := OrderedCollection new.
	"parse document"

	importer := FamixHtmlImporter new.
	importer model: FamixHtmlModel new.

	[
	importer importString: self text.
	MiApplication current buses do: [ :bus |
		bus globallySelect:
			(importer model detect: [ :en | en isKindOf: FamixHtmlDocument ]) ].

	violations := self server runCriticBrowserOn:
		              (importer model allWithType: FamixHtmlElement).
	violations do: [ :violation |
		diagnostics add:
			(self buildViolation: violation forDocument: self) ] ]
		on: SmaCCParserError
		do: [ :err |
			diagnostics add: (self buildSmaccErr: err forDocument: self) ].
	"return diagnostics"
	^ diagnostics
]
