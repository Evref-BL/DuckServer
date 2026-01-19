"
A BLLanguageServerTest is a test class for testing the behavior of BLLanguageServer
"
Class {
	#name : 'DuckLanguageServerTest',
	#superclass : 'TestCase',
	#instVars : [
		'server'
	],
	#category : 'DuckLanguageServer-Tests',
	#package : 'DuckLanguageServer-Tests'
}

{ #category : 'tests' }
DuckLanguageServerTest >> addJavaDocument [
	"missing the last ]"

	| textDocument |
	textDocument := Dictionary new.
	textDocument at: #uri put: 'src/my-package/Benoit.java'.
	textDocument at: #version put: '1'.
	textDocument at: #languageId put: 'java'.
	textDocument at: #text put: 'package my-package;

public class Benoit {
	
}'.

	server didOpen: textDocument
]

{ #category : 'running' }
DuckLanguageServerTest >> setUp [

	| fim |
	super setUp.
	server := DuckLanguageServer new.
	server clientOutStream: NullStream new.

	"Mock LLMAPI"
	fim := LLMAPI fim.
	fim stub performRequest willReturn: 'Hello Benoit'.
	LLMAPI stub fim willReturn: fim
]

{ #category : 'running' }
DuckLanguageServerTest >> tearDown [

	LLMAPI recoverFromGHMutation.
	super tearDown
]

{ #category : 'tests' }
DuckLanguageServerTest >> testCodeActionForDocumentAtRangeWithContext [

	| textDocument range context codeAction |
	textDocument := { (#uri -> 'src/my-package/Benoit.java') }
		                asDictionary.
	range := {
		         (#start -> {
			          (#character -> 1).
			          (#line -> 1) } asDictionary).
		         (#end -> {
			          (#character -> 1).
			          (#line -> 1) } asDictionary) } asDictionary.
	context := { (#diagnostics -> { {
		            (#source -> server serverName).
		            (#message -> 'This is a bug') } asDictionary }) }
		           asDictionary.
	codeAction := server
		              codeActionForDocument: textDocument
		              atRange: range
		              withContext: context.
	self assert: codeAction class equals: Array.
	self assert: (codeAction anyOne at: #kind) equals: #quickfix
]

{ #category : 'tests' }
DuckLanguageServerTest >> testCodeActionForDocumentAtRangeWithContextOtherSource [

	| textDocument range context codeAction |
	textDocument := { (#uri -> 'src/my-package/Benoit.java') }
		                asDictionary.
	range := {
		         (#start -> {
			          (#character -> 1).
			          (#line -> 1) } asDictionary).
		         (#end -> {
			          (#character -> 1).
			          (#line -> 1) } asDictionary) } asDictionary.
	context := { (#diagnostics -> { {
		            (#source -> #other).
		            (#message -> 'This is a bug') } asDictionary }) }
		           asDictionary.
	codeAction := server
		              codeActionForDocument: textDocument
		              atRange: range
		              withContext: context.
	self assert: codeAction class equals: Array.
	self assert: (codeAction anyOne at: #kind) equals: #quickfix
]

{ #category : 'tests' }
DuckLanguageServerTest >> testCodeActionForDocumentAtRangeWithContextWithoutSource [

	| textDocument range context codeAction |
	textDocument := { (#uri -> 'src/my-package/Benoit.java') }
		                asDictionary.
	range := {
		         (#start -> {
			          (#character -> 1).
			          (#line -> 1) } asDictionary).
		         (#end -> {
			          (#character -> 1).
			          (#line -> 1) } asDictionary) } asDictionary.
	context := { (#diagnostics
	            -> { { (#message -> 'This is a bug') } asDictionary }) }
		           asDictionary.
	codeAction := server
		              codeActionForDocument: textDocument
		              atRange: range
		              withContext: context.
	self assert: codeAction class equals: Array.
	self assert: (codeAction anyOne at: #kind) equals: #quickfix
]

{ #category : 'tests' }
DuckLanguageServerTest >> testFixEncodingOf [

	self
		assert: (server fixEncodingOf: 'Ã©crit des trucs')
		equals: 'écrit des trucs'
]

{ #category : 'tests' }
DuckLanguageServerTest >> testFixEncodingOfCorrect [

	self
		assert: (server fixEncodingOf: 'écrit des trucs')
		equals: 'écrit des trucs'
]

{ #category : 'tests' }
DuckLanguageServerTest >> testTextDocumentInlineCompletionWithContextPositionTextDocument [

	| result |
	self addJavaDocument.
	result := server
		          textDocumentInlineCompletionWithContext: nil
		          position: {
				          (#character -> 2).
				          (#line -> 2) } asDictionary
		          textDocument:
		          { (#uri -> 'src/my-package/Benoit.java') } asDictionary.
	self assert: (result at: #items) size equals: 1.
	self
		assert: ((result at: #items) anyOne at: #insertText)
		equals: 'Hello Benoit'
]

{ #category : 'tests' }
DuckLanguageServerTest >> testTextDocumentInlineCompletionWithContextPositionTextDocumentPositionTooLow [

	| result |
	self addJavaDocument.
	result := server
		          textDocumentInlineCompletionWithContext: nil
		          position: {
				          (#character -> -10).
				          (#line -> -20) } asDictionary
		          textDocument:
		          { (#uri -> 'src/my-package/Benoit.java') } asDictionary.
	self assert: (result at: #items) size equals: 1.
	self
		assert: ((result at: #items) anyOne at: #insertText)
		equals: 'Hello Benoit'
]

{ #category : 'tests' }
DuckLanguageServerTest >> testTextDocumentInlineCompletionWithContextPositionTextDocumentPositionTooMuch [

	| result |
	self addJavaDocument.
	result := server
		          textDocumentInlineCompletionWithContext: nil
		          position: {
				          (#character -> 100).
				          (#line -> 200) } asDictionary
		          textDocument:
		          { (#uri -> 'src/my-package/Benoit.java') } asDictionary.
	self assert: (result at: #items) size equals: 1.
	self
		assert: ((result at: #items) anyOne at: #insertText)
		equals: 'Hello Benoit'
]
