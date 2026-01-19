Class {
	#name : 'DuckFASTTypeScriptRules',
	#superclass : 'DuckTypeScriptRules',
	#category : 'DuckLanguageServer-Rules',
	#package : 'DuckLanguageServer-Rules'
}

{ #category : 'bls - rules' }
DuckFASTTypeScriptRules >> ruleCheckingCommentsInClass [

	^ DuckRule new
		  name: 'Rule related to comments counting in class';
		  entityType: FASTTypeScriptClassDeclaration;
		  condition: [ :entity |
			  (entity allWithScope: FASTTypeScriptComment) size = 0 ];
		  codeLens: [ :file :entity |
			  PLSCodeLens new
				  range: (PLSRange
						   start: (file text toLineCharacter: entity startPos + 1)
						   end: (file text toLineCharacter: entity startPos + 1));
				  command: (PLSCommand new
						   title: #'Duck: Don''t forget the comments in your class';
						   command: #'duck.generateComment';
						   arguments: {
								   file uri.
								   entity startPos.
								   entity endPos } yourself);
				  yourself ] yourself
]

{ #category : 'bls - rules' }
DuckFASTTypeScriptRules >> ruleCheckingCommentsInMethod [

	^ DuckRule new
		  name: 'Rule related to the comments INSIDE method';
		  "usually we have to check also for comments before method directly but this is related to siblings in FAST which is currently not working. But working for TreeSitter."
		  entityType: FASTTypeScriptMethodDefinition;
		  condition: [ :entity |
			  (entity allWithScope: FASTTypeScriptComment) size = 0 ];
		  codeLens: [ :file :entity |
			  PLSCodeLens new
				  range: (PLSRange
						   start: (file text toLineCharacter: entity startPos + 1)
						   end: (file text toLineCharacter: entity startPos + 1));
				  command: (PLSCommand new
						   title: 'Duck: Don''t forget the comments in your method';
						   command: #'duck.generateComment';
						   arguments: {
								   file uri.
								   entity startPos.
								   entity endPos } yourself);
				  yourself ] yourself
]
