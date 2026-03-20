AcNode {
	var <>id, <>behaviour, <>params, <>channels, <>activationCount, <>lastActivation;
	var <>active;

	*new {|id, behaviour, params, channels = 2|
		^super.newCopyArgs(id, behaviour, params ?? { () }, channels, 0, 0).init
	}

	init {
		active = false;
	}

	activate {|output = 0, fadeTime = 2, cause|
		Ndef(id).fadeTime = fadeTime;
		Ndef(id).reshaping = \elastic;
		Ndef(id).source = behaviour;
		params.keysValuesDo {|key, val|
			Ndef(id).set(key, val);
		};
		Ndef(id).play(output, channels);
		active = true;
		activationCount = activationCount + 1;
		lastActivation = Main.elapsedTime;
	}

	deactivate {|fadeTime = 2|
		Ndef(id).fadeTime = fadeTime;
		Ndef(id).stop;
		active = false;
	}

	set {|key, value|
		params[key] = value;
		if(active) { Ndef(id).set(key, value) };
	}

	printOn {|stream|
		stream << "AcNode(" << id << ", active: " << active << ", count: " << activationCount << ")";
	}
}