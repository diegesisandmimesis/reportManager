#charset "us-ascii"
//
// reportManagerSummarizeAction.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "reportManager.h"

modify CommandTranscript
	// This is MOSTLY a cut and paste of the stock summarizeAction()
	// logic.
	// The first arg is the same (function that takes a report as its
	// arg, returning boolean true if the report is to be summarized,
	// nil otherwise).
	// The second arg in this case is a vector that the matching reports
	// will be appended to.
	_sortSummarizeAction(cond) {
		local cnt, cur, i, idx, insIdx, ok, rpt, sVec, vec;

		sVec = new Vector();
		vec = new Vector(8);
		rpt = reports_;
		cnt = rpt.length();

		// Skip to the first report for the current action.
		i = 1;
		while(rpt[i].getAction() != gAction)
			i += 1;

		for( ; ; ++i) {
			ok = nil;

			if(i <= cnt) {
				cur = rpt[i];

				if(cond(cur)) {
					vec.append(cur);
					ok = true;
				} else if (cur.ofKind(ImplicitActionAnnouncement) || cur.ofKind(MultiObjectAnnouncement) || cur.ofKind(DefaultCommandReport) || cur.ofKind(ConvBoundaryReport)) {
					ok = true;
				}
			}
			if(!ok || i == cnt) {
				if(vec.length() > 1) {
					foreach (cur in vec) {
						idx = rpt.indexOf(cur);

						rpt.removeElementAt(idx);
						--i;
						--cnt;

						insIdx = idx;

						for(--idx ; idx > 0 && (rpt[idx].ofKind(ImplicitActionAnnouncement) || rpt[idx].ofKind(DefaultCommandReport) || rpt[idx].ofKind(ConvBoundaryReport)) ; --idx) ;

						if(idx > 0 && rpt[idx].ofKind(MultiObjectAnnouncement)) {
							rpt.removeElementAt(idx);
							--i;
							--cnt;
							--insIdx;

							if(idx <= rpt.length() && idx > 1 && rpt[idx].ofKind(ConvBeginReport) && rpt[idx-1].ofKind(ConvEndReport) && rpt[idx].actorID == rpt[idx-1].actorID) {
								rpt.removeRange(idx - 1, idx);
								i -= 2;
								cnt -= 2;
								insIdx -= 2;
							}
						}
					}

					sVec.append(new Vector(vec));
				}
				if(vec.length() > 0)
					vec.removeRange(1, vec.length());
			}
			if(i > cnt)
				break;
		}

		return(sVec);
	}

	// A summarizeAction() variation that groups reports by their
	// obj distinguisher announcement (the bolded object description
	// that appears in command reports involving multiple objects).
	sortedSummarizeAction(cond, sortFn, report) {
		local l, vec, vv;

		// Get a vector of contigutous report vectors.
		vec = _sortSummarizeAction(cond);

		// Unroll the report vector.
		l = new Vector();
		vec.forEach(function(o) {
			o.forEach(function(r) { l.append(r); });
		});
		

		// Get a vector of vectors from the sort function.
		vv = sortFn(l);

		// Go through the vector of vectors, generating a
		// report from each element (which is a vector of
		// reports, grouped by the sort function).
		vv.forEach(function(o) {
			reports_.append(new MainCommandReport(report(o)));
		});
/*
		// Vector for the distinguishers.
		l = new Vector(vec.length);

		// Vector of vectors for the reports grouped by distinguisher.
		vv = new Vector(vec.length);

		// Now we go through our report list...
		vec.forEach(function(o) {
			// ...each element is itself a vector of reports,
			// which we iterate over.
			o.forEach(function(r) {
				// Get the distinguisher for this report's
				// direct object.
				dist = r.dobj_.getBestDistinguisher(
					gAction.getResolvedObjList(
						DirectObject)) .name(r.dobj_);

				// See if we already know this one.  If not,
				// add it to the list and create a new vector
				// to hold all the reports matching it.
				if((idx = l.indexOf(dist)) == nil) {
					l.appendUnique(dist);
					vv.append(new Vector());
					idx = l.length;
				}

				// Add these reports to the appropriate vector.
				vv[idx] += r;
			});
		});

		// Go through our vector of vectors.  Each element of the
		// top-level vector is a vector of all the reports for a
		// particular distinguisher.
		vv.forEach(function(o) {
			txt = report(o);
			reports_.append(new MainCommandReport(txt));
		});
*/
	}
;