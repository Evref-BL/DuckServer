Class {
	#name : 'DuckFASTJavaRules',
	#superclass : 'DuckJavaRules',
	#category : 'DuckLanguageServer-Rules',
	#package : 'DuckLanguageServer-Rules'
}

{ #category : 'duck - rules' }
DuckFASTJavaRules >> ruleCheckingCommentsInClass [

	^ DuckRule new
		  name: 'Rule related to comments counting in class';
		  entityType: FASTJavaClassDeclaration;
		  condition: [ :entity |
			  (entity allWithScope: FASTJavaComment) size = 0 ];
		  codeLens: [ :file :entity |
			  PLSCodeLens new
				  range: (PLSRange
						   start: (file text toLineCharacter: entity startPos + 1)
						   end: (file text toLineCharacter: entity startPos + 1));
				  command: (PLSCommand new
						   title:
							   #'Duck: Don''t forget the comments in your class';
						   command: #'duck.generateComment';
						   arguments: {
								   file uri.
								   entity startPos.
								   entity endPos } yourself);
				  yourself ] yourself
]

{ #category : 'duck - rules' }
DuckFASTJavaRules >> ruleCheckingCommentsInMethod [

	^ DuckRule new
		  name: 'Rule related to comments INSIDE method';
		  entityType: FASTJavaMethodEntity;
		  condition: [ :entity |
			  (entity allWithScope: FASTJavaComment) size = 0 ];
		  codeLens: [ :file :entity |
			  PLSCodeLens new
				  range: (PLSRange
						   start: (file text toLineCharacter: entity startPos + 1)
						   end: (file text toLineCharacter: entity startPos + 1));
				  command: (PLSCommand new
						   title: #'Duck: Don''t forget the comments in your method';
						   command: #'duck.generateComment';
						   arguments: {
								   file uri.
								   entity startPos.
								   entity endPos } yourself);
				  yourself ] yourself
]
