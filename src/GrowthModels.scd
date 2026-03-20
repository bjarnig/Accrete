/*
	---- ---- ---- ---- Accrete 'GrowthModels' ---- ---- ---- ----
	Convenience wrappers around AcGrowth class methods.
*/

(

var g = ();

g[\preferential] = {|ev, graph, id, behaviour, params, numEdges = 2|
	AcGrowth.preferentialAttachment(graph, id, behaviour, params, numEdges)
};

g[\random] = {|ev, graph, id, behaviour, params, numEdges = 2|
	AcGrowth.randomAttachment(graph, id, behaviour, params, numEdges)
};

g[\smallWorld] = {|ev, graph, probability = 0.1|
	AcGrowth.smallWorldRewire(graph, probability)
};

g[\decay] = {|ev, graph, dt = 1.0|
	AcGrowth.decayEdges(graph, dt)
};

g

)
