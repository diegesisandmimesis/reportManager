#charset "us-ascii"
//
// reportManagerSorter.t
//
//	Transcript sorters.  This is for widgets that want to re-arrange
//	the transcript, specifically BEFORE any summaries are made.
//
//	This is for things like moving all failure reports to the end of
//	the transcript.
//
//
#include <adv3.h>
#include <en_us.h>

#include "reportManager.h"

class TranscriptSorter: TranscriptModifier
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

class MoveFailuresToEndOfTranscript: TranscriptSorter
	sortReports(vec) {
		local ar, idx, len, lst;

		if((idx = vec.indexWhich({
			x: x.isFailure && !x.ofKind(MultiObjectAnnouncement)
		})) == nil)
			return;

		len = vec.length;

		while((idx != nil) && (idx <= len)) {
			ar = findMultiObjectAnnouncementEndpoints(vec, idx);

			if(ar[1] == ar[2])
				break;

			lst = new Vector(ar[2] - ar[1] + 1).copyFrom(vec,
				ar[1], 1, ar[2] - ar[1] + 1);

			lst.forEach({ x: x.isFailure = true });

			vec.removeRange(ar[1], ar[2]);
			vec.appendAll(lst);

			len -= lst.length;

			idx = vec.indexWhich({
				x: x.isFailure
					&& !x.ofKind(MultiObjectAnnouncement)
			});
		}
	}
;

modify transcriptManager
	_transcriptSorters = perInstance(new Vector())

	defaultTranscriptSorters = static [
		MoveFailuresToEndOfTranscript
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
