#charset "us-ascii"
//
// reportManagerSummarizeAction.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "reportManager.h"

class PlaceholderReport: CommandReport
	serial = nil
	construct(n) { serial = n; }
	showMessage() {}
;

class ReportManagerSummary: MainCommandReport;

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

					sVec.append([ sVec.length + 1,
						new Vector(vec) ]);
					rpt.insertAt(insIdx,
						new PlaceholderReport(
							sVec.length));
					++cnt;
					++i;
				}
				if(vec.length() > 0)
					vec.removeRange(1, vec.length());
			}
			if(i > cnt)
				break;
		}

		return(sVec);
	}

	_markFailedReports(lst) {
		local i, j, idx0, idx1;

		for(i = 1; (i != nil) && (i <= lst.length); i++) {
			if(!lst[i].isFailure)
				continue;

			idx0 = _findMultiObjectAnnouncement(lst, i, -1);
			idx0 = (idx0 ? idx0 : 1);
			idx1 = _findMultiObjectAnnouncement(lst, i, 1);
			idx1 = (idx1 ? idx1 : lst.length);
			for(j = idx0; j <= idx1; j++)
				lst[j].isFailure = true;

			i = idx1;
		}
	}

	_findMultiObjectAnnouncement(lst, idx, dir) {
		while((idx > 1) && (idx <= lst.length)) {
			if(lst[idx].ofKind(MultiObjectAnnouncement))
				return(idx);
			idx += dir;
		}

		return(nil);
	}

	// A summarizeAction() variation that supports an explicit
	// sorting function to group the reports to be summarized together.
	sortedSummarizeAction(cond, sortFn, report) {
		local l, vec, vv;

		// Get a vector of contigutous report vectors.
		vec = _sortSummarizeAction(cond);

		// Unroll the report vector.
		l = new Vector();
		vec.forEach(function(o) {
			o[2].forEach(function(r) {
				r.rptSerial_ = o[1];
				l.append(r);
			});
		});

		_markFailedReports(l);
		
		// Get a vector of vectors from the sort function.
		vv = sortFn(l);

		// Go through the vector of vectors, generating a
		// report from each element (which is a vector of
		// reports, grouped by the sort function).
		vv.forEach(function(o) {
			local idx, min, r;

			r = new ReportManagerSummary(report(o));
			r.isFailure = o[1].isFailure;

			min = o[1].rptSerial_;
			o.forEach(function(rp) {
				if(rp.rptSerial_ < min) min = rp.rptSerial_;
			});

			idx = reports_.indexWhich({ x: x.serial == min });
			if(idx != nil)
				reports_.insertAt(idx, r);
			else
				reports_.append(r);
		});
	}
;
