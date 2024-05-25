#charset "us-ascii"
//
// reportManagerMarker.t
//
//	Logic for transcript markers.  This is for code that traverses
//	the entire transcript and JUST does markup.  The motivating design
//	case is the MarkFailuresInTranscript class, which goes through
//	the transcript and marks reports associated with a failure report
//	with isFailure = true (by default TADS3 only puts isFailure on
//	the failure report itself, not the other reports associated with
//	the same action).
//
//
#include <adv3.h>
#include <en_us.h>

#include "reportManager.h"

class TranscriptModifier: ReportManagerObject
	// Find the first multi-object announcement in the vector (first arg),
	// starting at the given index (second arg), moving in the given
	// direction (third arg).  Direction is -1 (backwards) or 1 (forwards).
	findMultiObjectAnnouncement(vec, idx, dir) {
		while((idx >= 1) && (idx <= vec.length)) {
			if(vec[idx].ofKind(MultiObjectAnnouncement))
				return(idx);
			idx += dir;
		}

		return(nil);
	}

	findMultiObjectAnnouncementEndpoints(vec, idx) {
		local idx0, idx1;

		idx0 = findMultiObjectAnnouncement(vec, idx, -1);
		idx0 = (idx0 ? idx0 : 1);
		idx1 = findMultiObjectAnnouncement(vec, idx, 1);
		idx1 = (idx1 ? idx1 - 1: vec.length);

		return([ idx0, idx1 ]);
	}
;

class TranscriptMarker: TranscriptModifier
	initializeTranscriptMarker() {
		if(location == nil)
			return(nil);
		if(location == transcriptManager) {
			location.addTranscriptMarker(self);
			return(true);
		}

		return(nil);
	}

	markReports(vec) {}
;

// Go through a list of reports, looking for failures.
// When we find one, we look for the multi-object announcement
// before and after the failure report and mark all reports
// in between as failures.
class MarkFailuresInTranscript: TranscriptMarker
	markReports(vec) {
		local idx, i, j;
		//local i, j, idx0, idx1;

		for(i = 1; (i != nil) && (i <= vec.length); i++) {
			if(!vec[i].isFailure)
				continue;

			idx = findMultiObjectAnnouncementEndpoints(vec, i);
/*
			idx0 = findMultiObjectAnnouncement(vec, i, -1);
			idx0 = (idx0 ? idx0 : 1);
			idx1 = findMultiObjectAnnouncement(vec, i, 1);
			idx1 = (idx1 ? idx1 : vec.length);
*/
			for(j = idx[1]; j <= idx[2]; j++)
				vec[j].isFailure = true;

			i = idx[2];
		}
	}
;


modify transcriptManager
	_transcriptMarkers = perInstance(new Vector())

	defaultTranscriptMarkers = static [
		//MarkFailuresInTranscript
	]

	initializeTranscriptManager() {
		inherited();
		initializeTranscriptManagerDefaultMarkers();
	}

	initializeTranscriptManagerDefaultMarkers() {
		local i, l;

		if(defaultTranscriptMarkers == nil)
			return;

		if(!defaultTranscriptMarkers.ofKind(Collection))
			defaultTranscriptMarkers = [ defaultTranscriptMarkers ];
			
		l = new Vector(defaultTranscriptMarkers.length);

		defaultTranscriptMarkers.forEach(function(o) {
			for(i = 1; i <= _transcriptMarkers.length; i++) {
				if(_transcriptMarkers[i].ofKind(o))
					return;
			}
			l.appendUnique(o);
		});

		l.forEach(function(o) {
			addTranscriptMarker(o.createInstance());
		});
	}

	addTranscriptMarker(obj) {
		if((obj == nil) || !obj.ofKind(TranscriptMarker))
			return(nil);

		_transcriptMarkers.append(obj);

		return(true);
	}

	markTranscript(vec) {
		_transcriptMarkers.forEach(function(o) {
			(o).markReports(vec);
		});
	}
;
