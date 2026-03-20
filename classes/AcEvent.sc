AcEvent {
	var <>type, <>target, <>cause, <>timestamp, <>data;

	*new {|type, target, cause, data|
		^super.newCopyArgs(type, target, cause, Main.elapsedTime, data)
	}

	printOn {|stream|
		stream << "AcEvent(" << type << ", " << target << ", cause: " << cause << ", t: " << timestamp.round(0.01) << ")";
	}
}