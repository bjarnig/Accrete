Accrete {
	var <>basePath, <>behaviours, <>processing, <>observers, <>growth;

	*new {|interpreter|
		^super.newCopyArgs().init(interpreter)
	}

	init {|interpreter|
		basePath = PathName(Accrete.filenameSymbol.asString).pathOnly.replace("classes/", "src/");

		behaviours = interpreter.compileFile(basePath ++ "Behaviours.scd").value;
		processing = interpreter.compileFile(basePath ++ "Processing.scd").value;
		observers = interpreter.compileFile(basePath ++ "Observers.scd").value;
		growth = interpreter.compileFile(basePath ++ "GrowthModels.scd").value;

		^this
	}

	behaviourNames { ^behaviours.keys.asArray }
	processingNames { ^processing.keys.asArray }
	observerNames { ^observers[\features].keys.asArray }
	growthNames { ^growth.keys.asArray }
}