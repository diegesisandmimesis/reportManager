#charset "us-ascii"
//
// reportManagerSummary.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "reportManager.h"

class ReportSummaryData: object
	dobj = nil		// representative object for this summary
	objs = nil		// vector of objects
	vec = nil		// vector of reports being summarized
	count = nil		// count of objects being summarized
	prep = nil		// boolean, if true supply prepositional
				//	announcement ("pebble in box:") for
				//	the summary

	construct(v, o, ol, p) {
		vec = v;
		dobj = o;
		objs = ol;
		prep = p;

		count = dobj._reportCount;
	}
;

class ReportSummary: ReportManagerObject
	action = nil

	reportManager = nil

	initializeReportSummary() {
		if(location == nil)
			return(nil);
		if(location.ofKind(ReportManager)) {
			location.addReportManagerSummary(self);
			return(true);
		}

		return(nil);
	}

	matchAction(act) {
		if((act == nil) || (action == nil))
			return(nil);

		return(act.ofKind(action));
	}

	// Figure out if all the objects being summarized are in the
	// same location or not.  If so, we don't have anything special
	// to do.  If not, then we group everything by location and
	// include a prepositional announcement before each summary (indicating
	// which group of objects each summary applies to:  "pebbles in the
	// box" versus "pebbles carried by Bob" and so on).
	summarizeByLocation(vec, txt) {
		local dobjs, i, locs, n, obj, oList, vecs;

		if((vec == nil) || (vec.length < 1))
			return;

		locs = new Vector(vec.length);
		dobjs = new Vector(vec.length);
		oList = new Vector(vec.length);
		vecs = new Vector(vec.length);

		vec.forEach(function(o) {
			if(o.dobj_ == nil)
				return;
			if((i = locs.indexOf(o.dobj_.location)) == nil) {
				locs.appendUnique(o.dobj_.location);
				dobjs.append(o.dobj_);
				oList.append(new Vector());
				vecs.append(new Vector());
				i = locs.length;
			}
			vecs[i].append(o);
		});

		for(i = 1; i <= locs.length; i++) {
			n = 0;
			gAction.dobjList_.forEach(function(o) {
				if(o.obj_.reportManager != reportManager)
					return;
				if(o.obj_.location != locs[i])
					return;
				oList[i].append(o.obj_);
				n += 1;
			});
			dobjs[i]._reportCount = n;
		}

		for(i = 1; i <= locs.length; i++) {
			obj = new ReportSummaryData(vecs[i], dobjs[i],
				oList[i], (locs.length > 1));

			reportSummaryMessageParams(obj.dobj);
			reportManager.reportManagerAnnouncement(obj, txt);
			txt.append(summarize(obj));
		}
	}

	reportSummaryMessageParams(obj?) {}

	summarize(data) {}
;
