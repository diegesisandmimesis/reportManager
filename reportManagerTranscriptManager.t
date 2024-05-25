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
	reportID = 'transcriptManager'

	active = true

	reportManagerDefaultSummaries = static [
		TakeSummary,
		TakeFromSummary,
		DropSummary,
		PutOnSummary,
		PutInSummary,
		PutUnderSummary,
		PutBehindSummary
	]

	_transcriptTimestamp = nil

	// We match any non-nil object.
	matchReportDobj(obj) { return(obj != nil); }

	// TAction and TIActions call us from their afterActionMain().  This
	// is the main external hook for the report manager logic.
	afterActionMain() {
		if(!checkTranscriptManager())
			return;
		runTranscriptManager();
	}

	// See if we should run this turn.  Returns true if we should,
	// nil otherwise.
	checkTranscriptManager() {
		// Make sure we're active.
		if(getActive() != true)
			return(nil);

		// We only care about reports for transitive verbs.
		if(gAction.dobjList_ == nil)
			return(nil);

		if(_transcriptTimestamp == gTurn)
			return(nil);

		return(true);
	}

	// Main report manager loop.
	runTranscriptManager() {
		local i, idx, lst, sl, sv, vec, vv;

		_transcriptTimestamp = gTurn;

		// Start out every turn assuming we don't need to use
		// distinguishers.
		_distinguisherFlag = nil;

		lst = gTranscript.reports_;

		//_debugReportVector(lst, 'before pre-processing', reportID);

		// Run our transcript markers.
		markTranscript(lst);

		// Run the transcript sorters.
		sortTranscript(lst);

		// Summarize the implicit actions
		summarizeImplicit(lst);

		//_debugReportVector(lst, 'after preprocessing', reportID);

		// Get a vector of vectors of the reports in the transcript.
		// The return value will be a vector in which each of the
		// elements is a vector of contiguous reports matching one
		// or more of our summary criteria.
		vec = getReportVector(lst);

		// Vector for the summarizer list.
		sl = new Vector();

		// Vector of vectors of reports sorted by the summarizer
		// that will handle them.
		vv = new Vector();


		// Go through the flattened list of reports and group
		// them by summarizer.
		vec.forEach(function(o) {
			// No summarizer, nothing to do.
			if(o.reportSummarizer == nil)
				return;

			// Maintain a list of summarizers we're using.
			if((idx = sl.indexOf(o.reportSummarizer)) == nil) {
				// Add this summarizer to the list.
				sl.appendUnique(o.reportSummarizer);

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

	defaultCheckReport(report) {
		return(report.ofKind(ImplicitActionAnnouncement)
			|| report.ofKind(MultiObjectAnnouncement)
			|| report.ofKind(DefaultCommandReport)
			|| report.ofKind(ConvBoundaryReport));
	}

	getReportVector(lst) {
		local i, vec;

		vec = new Vector(lst.length);

		lst.forEach(function(o) {
			if(o.action_ != gAction)
				return;
			if(checkReport(o))
				vec.append(o);
		});

		for(i = 1; i <= vec.length; i++) {
			vec[i].reportID = i;
			removeReports(vec[i]);
		}

		return(vec);
	}

	removeReports(report) {
		local idx, lst, rIdx;

		lst = gTranscript.reports_;

		if((idx = lst.indexOf(report)) == nil)
			return;

		lst.removeElementAt(idx);
		rIdx = idx;

		idx -= 1;

		// Skip back past announcements and markers for the report
		// we just removed.
		while((idx >= 1) && (lst[idx].ofKind(ImplicitActionAnnouncement)
			|| lst[idx].ofKind(DefaultCommandReport)
			|| lst[idx].ofKind(ConvBoundaryReport)))
			idx -= 1;

		// If the prior report is a multi object announcement for
		// the object we just removed, remove it as well.
		if((idx >= 1) && (lst[idx].ofKind(MultiObjectAnnouncement))) {
			lst.removeElementAt(idx);
			rIdx -= 1;

			// Check to see if what we've removed has resulted
			// in a conversation end immediately followed by a
			// conversation begin involving the same actor.  If
			// so, remove the conversation end markers to turn
			// it into one continuous conversation.
			if((idx > 1) && (idx <= lst.length)
				&& lst[idx].ofKind(ConvBeginReport)
				&& lst[idx - 1].ofKind(ConvEndReport)
				&& (lst[idx].actorID == lst[idx - 1].actorID)) {
				rIdx -= 2;
			}
		}

		lst.insertAt(rIdx, new PlaceholderReport(report.reportID));
	}

	// Figure out who, if anyone, wants to summarize this report.
	checkReport(report) {
		// Make sure the report pertains to the current action.
		if(report.action_ != gAction)
			return(nil);

		// We don't handle our own summaries.
		if(report.ofKind(ReportManagerSummary))
			return(nil);

		if(report.ofKind(PlaceholderReport))
			return(nil);

		// See if the report can figure out who wants to summarize
		// it.  This will ping the report's dobj's report manager,
		// if there is one.
		if(report.getReportSummarizer() != nil) {
			return(true);
		}

		// Nobody else claimed it, so see if one of our stock
		// summarizers wants to handle it.
		return((report.reportSummarizer = getReportSummarizer(report))
			!= nil);
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

		// First, guess the first report's numeric reportID.
		min = vec[1].reportID;

		// Now go through the rest of the reports for this summary,
		// seeing if any has a lower ID.
		vec.forEach(function(rpt) {
			if(rpt.reportID < min)
				min = rpt.reportID;
		});

		// Find the index of the report that matches the lowest
		// serial number from the summary.
		idx = gTranscript.reports_.indexWhich({ x: x.reportID == min });

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

	setDistinguisherFlag() { _distinguisherFlag = true; }

	markTranscript(vec) {}
	sortTranscript(vec) {}
	summarizeImplicit(vec) {}
;
