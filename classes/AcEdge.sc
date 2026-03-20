AcEdge {
	var <>from, <>to, <>weight, <>type, <>paramMap, <>decayRate;

	*new {|from, to, weight = 1.0, type = \succession, paramMap, decayRate = 0.0|
		^super.newCopyArgs(from, to, weight, type, paramMap ?? { Dictionary.new }, decayRate)
	}

	decay {|dt = 1.0|
		weight = (weight - (decayRate * dt)).max(0);
	}

	printOn {|stream|
		stream << "AcEdge(" << from << " -> " << to << ", w: " << weight.round(0.01) << ", " << type << ")";
	}
}