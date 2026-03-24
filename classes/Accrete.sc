Accrete {
	var <>basePath, <>behaviours, <>processing, <>observers, <>growth, <>averse;

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

	loadAverse {|interpreter, bufferPath|
		// load buffers first, then compile behaviours that reference ~hpb
		averse = ();
		averse[\loadBuffers] = {|ev, server, path|
			var hpb = Dictionary();
			"abcdefghijk".do {|letter|
				var folder = path ++ "/hp" ++ letter ++ "/*";
				var files = SoundFile.collect(folder);
				if(files.notNil and: { files.notEmpty }) {
					hpb[letter.asString] = files.collect {|sf|
						Buffer.readChannel(server, sf.path, channels: 0)
					};
				};
			};
			~hpb = hpb;
			"Accrete: loaded % buffer sets from %".format(hpb.size, path).postln;
			hpb
		};
		averse[\loadBuffers].value(averse, Server.default, bufferPath);
		Server.default.sync;
		averse = interpreter.compileFile(basePath ++ "AverseBehaviours.scd").value;
		^averse
	}

	behaviourNames { ^behaviours.keys.asArray }
	processingNames { ^processing.keys.asArray }
	observerNames { ^observers[\features].keys.asArray }
	growthNames { ^growth.keys.asArray }
	averseNames { ^if(averse.notNil) { averse[\names].value } { [] } }
}