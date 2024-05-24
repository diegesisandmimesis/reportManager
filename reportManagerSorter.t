#charset "us-ascii"
//
// reportManagerSorter.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "reportManager.h"

class TranscriptSorter: ReportManagerObject
	initializeTranscriptSorter() {
		if(location == nil)
			return(nil);
		if(location == transcriptManager) {
			location.addTranscriptSorter(self);
			return(true);
		}

		return(nil);
	}

	sortReports(vec) {}
;

modify transcriptManager
	_transcriptSorters = perInstance(new Vector())

	defaultTranscriptSorters = static [
	]

	initializeTranscriptManager() {
		inherited();
		initializeTranscriptManagerDefaultSorters();
	}

	initializeTranscriptManagerDefaultSorters() {
		local i, l;

		if(defaultTranscriptSorters == nil)
			return;

		if(!defaultTranscriptSorters.ofKind(Collection))
			defaultTranscriptSorters = [ defaultTranscriptSorters ];
			
		l = new Vector(defaultTranscriptSorters.length);

		defaultTranscriptSorters.forEach(function(o) {
			for(i = 1; i <= _transcriptSorters.length; i++) {
				if(_transcriptSorters[i].ofKind(o))
					return;
			}
			l.appendUnique(o);
		});

		l.forEach(function(o) {
			addTranscriptSorter(o.createInstance());
		});
	}

	addTranscriptSorter(obj) {
		if((obj == nil) || !obj.ofKind(TranscriptSorter))
			return(nil);

		_transcriptSorters.append(obj);

		return(true);
	}

	sortTranscript(vec) {
		_transcriptSorters.forEach(function(o) {
			(o).sortReports(vec);
		});
	}
;
