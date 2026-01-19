Class {
	#name : 'BaselineOfDuckLanguageServer',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfDuckLanguageServer',
	#package : 'BaselineOfDuckLanguageServer'
}

{ #category : 'baselines' }
BaselineOfDuckLanguageServer >> baseline: spec [

	<baseline>
	self defineDependencies: spec.
	self definePackages: spec.
	self defineGroups: spec
]

{ #category : 'baselines' }
BaselineOfDuckLanguageServer >> defineDependencies: spec [

	spec
		baseline: 'PharoLanguageServer'
		with: [
		spec repository: 'github://badetitou/Pharo-LanguageServer:5.0.4/src' ].
	spec
		baseline: 'FamixJavaModelUpdater'
		with: [
		spec repository: 'github://Evref-BL/FamixJavaModelUpdater:2.0.2/src' ].
	"spec
		baseline: 'FASTTypeScript'
		with: [
		spec repository: 'github://moosetechnology/FASTTypescript:main' ]." 
	spec
		baseline: 'FamixTypeScriptModelUpdater'
		with: [
		spec repository: 'github://Evref-BL/FamixTypeScriptModelUpdater:main/src' ].
	spec
		baseline: 'PetitParser2'
		with: [ spec repository: 'github://kursjan/petitparser2' ].
	spec
		baseline: 'FamixHtml'
		with: [ spec repository: 'github://Evref-BL/Famix-Html:main/src' ].
	spec
		baseline: 'LLMAPI'
		with: [ spec repository: 'github://Evref-BL/Pharo-LLMAPI:1.0.4/src' ].

	spec
		baseline: 'Mocketry'
		with: [
		spec repository: 'github://dionisiydk/Mocketry:versionTagOrBranch' ]
]

{ #category : 'baselines' }
BaselineOfDuckLanguageServer >> defineGroups: spec [
]

{ #category : 'baselines' }
BaselineOfDuckLanguageServer >> definePackages: spec [

	spec package: 'DuckLanguageServer' with: [
		spec requires: #( 'PharoLanguageServer' 'FamixJavaModelUpdater'
			   'FamixHtml' 'LLMAPI' ) ].

	spec
		package: 'DuckLanguageServer-Tests'
		with: [ spec requires: #( 'DuckLanguageServer' 'Mocketry' ) ]
]
