#charset "us-ascii"
//
// reportManagerTranscriptManager.t
//
//	Global report manager singleton.  This handles report summaries
//	that aren't tied to specific objects/classes.
//
//	This is intended to be a more-or-less workalike for Eric Eve's
//	Combine Reports module (extensions/combineReports.t).  Earlier
//	versions of this module were designed to work alongside
//	combineReports.t, but simultaneously summarizing success reports
//	and failure reports turned out to be much more straightforward
//	with a single report management scheme.
//
//	Summaries can be added to the transcriptManager singleton,
//	to be applied to objects in general.
//
//	Precedence is from specific to general, so any other report
//	manager that matches the object type will be used in preference
//	to the global report manager.
//
//
#include <adv3.h>
#include <en_us.h>

#include "reportManager.h"

// Global singleton to handle "generic", non-object-specific report
// summaries.
transcriptManager: ReportManager
	reportID = 'reportManager'

	active = true

	reportManagerDefaultSummaries = static [
		TakeSummary,
		TakeFromSummary,
		DropSummary,
		PutOnSummary,
		PutInSummary,
		PutUnderSummary,
		PutBehindSummary,
		ImplicitTakeSummary
	]

	// We match any non-nil object.
	matchReportDobj(obj) { return(obj != nil); }

	// TAction and TIActions call us from their afterActionMain().  This
	// is the main external hook for the report manager logic.
	afterActionMain() {
		if(!validateReportManager())
			return;
		runReportManager();
	}

	// See if we should run this turn.  Returns true if we should,
	// nil otherwise.
	validateReportManager() {
		// Make sure we're active.
		if(getActive() != true)
			return(nil);

		// We only care about reports for transitive verbs.
		if(gAction.dobjList_ == nil)
			return(nil);

		return(true);
	}

	// Main report manager loop.
	runReportManager() {
		local i, idx, l, sl, sv, vec, vv;

		// Start out every turn assuming we don't need to use
		// distinguishers.
		_distinguisherFlag = nil;

		// By default a failed action will produce at least two
		// reports:  one containing the failure message, which will
		// NOT be marked as a failure; and a "blank" report marked
		// as a failure.  This will go through and mark all of the
		// reports associated with a failed action as failed.
		markFailedReports(gTranscript.reports_);

		summarizeImplicit();

		// Get a vector of vectors of the reports in the transcript.
		// The return value will be a vector in which each of the
		// elements is a vector of contiguous reports matching one
		// or more of our summary criteria.
		vec = getReportVector();

		// Flatten out the vector of vectors into a single vector
		// of reports.
		l = unrollReportVector(vec);

		// Vector for the summarizer list.
		sl = new Vector();

		// Vector of vectors of reports sorted by the summarizer
		// that will handle them.
		vv = new Vector();


		// Go through the flattened list of reports and group
		// them by summarizer.
		l.forEach(function(o) {
			// No summarizer, nothing to do.
			if(o.rptSummarizer_ == nil)
				return;

			// Maintain a list of summarizers we're using.
			if((idx = sl.indexOf(o.rptSummarizer_)) == nil) {
				// Add this summarizer to the list.
				sl.appendUnique(o.rptSummarizer_);

				// Create a vector to hold reports for
				// this summarizer.
				vv.append(new Vector());

				// Make note of the index of the summarizer
				// we just saved.
				idx = sl.length;
			}

			// Add this report to the appropriate summarizer's
			// list.
			vv[idx].append(o);
		});

		// If we're using multiple summarizers, we have to use
		// distinguishers.
		// We ALSO want to use distinguishers if any one summary
		// uses them.  See note below.
		if(sl.length > 1)
			setDistinguisherFlag();

		// Go through the list of summarizers created above...
		for(i = 1; i <= sl.length; i++) {
			// ...and have the summarizer's report manager
			// sort that summarizer's reports.
			sv = sl[i].reportManager.sortReports(vv[i]);

			// If this summarizer needs distinguishers, we
			// set the distinguisher flag.  In theory we
			// want ALL summaries to use distinguishers if
			// ANY do, but if there is more than one summarizer
			// then this flag would already be set.
			if(sv.length > 1)
				setDistinguisherFlag();

			// Then, having sorted them, have each summarizer
			// actually summarize the sorted reports.
			sv.forEach(function(o) {
				handleSummary(sl[i], o);
			});
		}
	}

	// Returns a vector of vectors of the reports in the transcript.
	// Each element of the "outer" vector will be a vector of
	// contiguous reports matching one or more of our reporting
	// criteria.
	getReportVector() {
		return(gTranscript._sortSummarizeAction(function(rpt) {
			return(checkReport(rpt));
		}));
	}

	// Figure out who, if anyone, wants to summarize this report.
	checkReport(report) {
		// Make sure the report pertains to the current action.
		if(report.action_ != gAction)
			return(nil);

		// We don't handle our own summaries.
		if(report.ofKind(ReportManagerSummary))
			return(nil);

		// See if the report can figure out who wants to summarize
		// it.  This will ping the report's dobj's report manager,
		// if there is one.
		if(report.getReportSummarizer() != nil) {
			return(true);
		}

		// Nobody else claimed it, so see if one of our stock
		// summarizers wants to handle it.
		return((report.rptSummarizer_ = getReportSummarizer(report))
			!= nil);
	}

	// Flatten a vector-of-vectors of reports into a single vector.
	unrollReportVector(vec) {
		local l;

		l = new Vector();

		vec.forEach(function(o) {
			o[2].forEach(function(r) {
				r.rptSerial_ = o[1];
				l.append(r);
			});
		});

		return(l);
	}

	// Handle a single summary.  Args are the summarizer object
	// and a vector of the reports to be summarized.
	handleSummary(s, vec) {
		local idx, min, r;

		// Get the summarizer to summarize the report.  The return
		// value is itself a report.
		r = s.summarizeReports(vec);
		r.isFailure = vec[1].isFailure;

		// Figure out where to insert the summary into the transcript's
		// list of reports.

		// First, guess the first report's "serial number";
		min = vec[1].rptSerial_;

		// Now go through the rest of the reports for this summary,
		// seeing if any has a lower serial number.
		vec.forEach(function(rpt) {
			if(rpt.rptSerial_ < min)
				min = rpt.rptSerial_;
		});

		// Find the index of the report that matches the lowest
		// serial number from the summary.
		idx = gTranscript.reports_.indexWhich({ x: x.serial == min });

		// If we found a matching report, insert the summary near
		// it.  This should place the summary at the same place as
		// the reports it's replacing.
		// If we couldn't find a matching report, just tack the
		// summary onto the end of the report list.
		if(idx != nil)
			gTranscript.reports_.insertAt(idx, r);
		else
			gTranscript.reports_.append(r);
	}

	// Go through a list of reports, looking for failures.
	// When we find one, we look for the multi-object announcement
	// before and after the failure report and mark all reports
	// in between as failures.
	markFailedReports(lst) {
		local i, j, idx0, idx1;

		for(i = 1; (i != nil) && (i <= lst.length); i++) {
			if(!lst[i].isFailure)
				continue;

			idx0 = findMultiObjectAnnouncement(lst, i, -1);
			idx0 = (idx0 ? idx0 : 1);
			idx1 = findMultiObjectAnnouncement(lst, i, 1);
			idx1 = (idx1 ? idx1 : lst.length);
			for(j = idx0; j <= idx1; j++)
				lst[j].isFailure = true;

			i = idx1;
		}
	}

	summarizeImplicit() {
		_reportManagerSummary.forEach(function(o) {
			if(o.isImplicit != true)
				return;
			o._summarizeImplicit();
		});
	}

	findMultiObjectAnnouncement(lst, idx, dir) {
		while((idx > 1) && (idx <= lst.length)) {
			if(lst[idx].ofKind(MultiObjectAnnouncement))
				return(idx);
			idx += dir;
		}

		return(nil);
	}

	setDistinguisherFlag() { _distinguisherFlag = true; }
;
