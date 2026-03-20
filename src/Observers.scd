/*
	---- ---- ---- ---- Accrete 'Observers' ---- ---- ---- ----
	Feature extractors — each is a UGen function: {|sig| ... }
	Returns analysis values for SendReply via AcObserver.
*/

(

var o = ();

o[\features] = (

	amplitude: {|sig|
		var amp = Amplitude.kr(sig.mean, 0.01, 0.1);
		[amp]
	},

	pitch: {|sig|
		var freq = Pitch.kr(sig.mean)[0];
		var hasFreq = Pitch.kr(sig.mean)[1];
		[freq, hasFreq]
	},

	centroid: {|sig|
		var chain = FFT(LocalBuf(2048), sig.mean);
		var centroid = SpecCentroid.kr(chain);
		[centroid]
	},

	flatness: {|sig|
		var chain = FFT(LocalBuf(2048), sig.mean);
		var flat = SpecFlatness.kr(chain);
		[flat]
	},

	onsets: {|sig|
		var chain = FFT(LocalBuf(512), sig.mean);
		var onset = Onsets.kr(chain, 0.3);
		[onset]
	},

	zeroCrossing: {|sig|
		var zc = ZeroCrossing.ar(sig.mean);
		var zcSmooth = A2K.kr(Lag.ar(zc, 0.1));
		[zcSmooth]
	}
);

o

)
