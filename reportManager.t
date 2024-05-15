#charset "us-ascii"
//
// reportManager.t
//
//	A TADS3/adv3 module for implementing per-object/class report
//	managers.
//
//	This is designed to complement the approach taken by
//	Eric Eve's Combine Reports extension, which provides report
//	management on a per-Action basis.
//
//
// USAGE
//
//	Consider the case where you have a pebble and three balls of different
//	colors in a location and the player decides to >X ALL
//
//		>X ALL
//		pebble: A small, round pebble.
//
//		blue ball: A blue ball.
//
//		green ball: A green ball.
//
//		red ball: A red ball.
//
//	The goal is to merge the ball reports into a single message while
//	still handling the pebble report separately.
//
//	To do this we'll implement a report manager for the balls, which
//	we'll call, unimaginatively, ballReportManager:
//
//		// Declare the report manager.
//		ballReportManager: ReportManager;
//
//	Now in the definition of our ball objects, we tell them to use
//	this report manager:
//
//		// A base class for the ball objects.
//		class Ball: Thing 'ball*balls' 'ball' "A ball. "
//			reportManager = ballReportManager
//		;
//			
//	We then have to write the code that's actually going to do the
//	summarizing.  We do this by adding ReportSummary objects to the report
//	manager.
//
//	Each ReportSummary needs to define:
//
//		action
//			property defining what Action class it applies to
//
//		summarize(vec, txt)
//			method taking two arguments:  a vector of the
//			reports being summarized and a StringBuffer to
//			write the summary to.
//
//	An example:
//
//		ballReportManager: ReportManager
//			// We only summarize reports involving Ball instances.
//			checkReport(report) {
//				return(gReportObjectOfKind(Ball));
//			}
//		;
//		+ReportSummary
//			// We summarize >EXAMINE reports
//			action = ExamineAction
//
//			// Actually summarize the reports.
//			summarize(vec, txt) {
//				local l;
//
//				// Make sure we have data to summarize.
//				// Here we use a convenience method to get
//				// the objects from the report manager instead
//				// of digging through the reports ourselves.
//				if((l = reportManager.getReporObjects()) == nil)
//					return;
//
//				// Use objectLister to make the summary.
//				txt.append('It\'s
//					<<objectLister.makeSimpleList(l)>>. ');
//			}
//		;
//
//	Now the result of >X ALL will be:
//
//		>X ALL
//		pebble: A small, round pebble.
//		balls: It's a red ball, a blue ball, and a green ball.
//
//		>X BALLS
//		It's a blue ball, a green ball, and a red ball.
//		
//
//
#include <adv3.h>
#include <en_us.h>

#include "reportManager.h"

// Module ID for the library
reportManagerModuleID: ModuleID {
        name = 'Report Manager Library'
        byline = 'Diegesis & Mimesis'
        version = '1.0'
        listingOrder = 99
}

// The report manager object.
class ReportManager: object
	// What kind of object we're a manager for
	reportManagerFor = nil

	// Minimum number of reports needed to summarize.
	// If an action doesn't produce at least this many, we won't
	// do anything.
	minSummaryLength = 2

	// Announcement text for actions where there's a mixture of
	// summarized and non-summarized reports.  For example, if
	// we have a pebble and three balls and we're summarizing the
	// balls but not the pebble, we'll get something like:
	//
	//	>X ALL
	//	pebble: A small, round pebble.
	//	foo: It's a red ball, a blue ball, and a green ball.
	//
	// This controls what text is used for "foo" in the example above.
	// If nil, then no announcement text will be used (and the summary
	// will just be listed in a line by itself).
	reportManagerAnnounceText = nil

	// An optional list of ReportSummary classes to add to the report
	// manager.
	// Each summary handles a kind of Action, so if we have a list
	// default summaries we go through the list of summaries already
	// declared on the report manager and add a default for any
	// Action that isn't already handled.
	reportManagerDefaultSummaries = nil

	// List of our summary objects.
	_reportManagerSummary = perInstance(new Vector())

	// Property to hold the reports for a specific action.  Set
	// by the summarizeReports() wrapper, we just store this so
	// we don't have to juggle it as an argument for the summary
	// methods.
	_reportManagerReports = nil

	// Used internally to make sure we only summarize things once
	// per action.
	_summarizeFlag = nil

	_summarizedReports = nil

	// Preinit method.
	initializeReportManager() {
		initializeReportManagerFor();
		initializeReportManagerDefaultSummaries();
	}

	// Go through all the objects we're the report manager for and
	// make sure they know about us.
	initializeReportManagerFor() {
		if(reportManagerFor == nil)
			return;

		forEachInstance(reportManagerFor, function(o) {
			o.reportManager = self;
		});
	}

	// Check to see if there are any default summaries that we don't
	// already have copies of.
	initializeReportManagerDefaultSummaries() {
		local l;

		// No default summaries, nothing to do.
		if(reportManagerDefaultSummaries == nil)
			return;

		// Make sure the list of defaults is list-ish.
		if(!reportManagerDefaultSummaries.ofKind(Collection))
			reportManagerDefaultSummaries
				= [ reportManagerDefaultSummaries ];

		// This will hold the summaries we need to add.
		l = new Vector(reportManagerDefaultSummaries.length);

		// Go through the list of defaults, checking to see
		// if we already have a summary for its action.
		reportManagerDefaultSummaries.forEach(function(o) {
			// If we already have a summary for this
			// action, bail.
			if(getSummaryForAction(o.action))
				return;

			// Remember that we need to add this default.
			l.appendUnique(o);
		});

		// Go through our list of defaults we don't have,
		// adding them.
		l.forEach(function(o) {
			addReportManagerSummary(o.createInstance());
		});
	}

	// Returns the summary for the given action, if we have one.
	getSummaryForAction(act) {
		local i;

		for(i = 1; i <= _reportManagerSummary.length; i++) {
			if(_reportManagerSummary[i].matchAction(act))
				return(_reportManagerSummary[i]);
		}

		return(nil);
	}

	// Add a summary to our list.
	addReportManagerSummary(obj) {
		// Make sure it's valid.
		if((obj == nil) || !obj.ofKind(ReportSummary))
			return(nil);

		// Add it.
		_reportManagerSummary.appendUnique(obj);
		// Have it remember us.
		obj.reportManager = self;

		return(true);
	}

	// Returns a list of all the objects in the reports we're
	// summarizing.
	// Optional arg is a vector of reports.  If not specified, we'll
	// use our saved copy of the "complete" list of reports for
	// this action.
	getReportObjects(vec?) {
		local r;

		// See if we got an argument or we're using the default.
		if(vec == nil)
			vec = _reportManagerReports;

		// If we couldn't figure it out, bail.
		if(vec == nil)
			return(nil);

		// Vector for results.
		r = new Vector(vec.length);

		vec.forEach(function(o) {
			if(o.dobj_ == nil)
				return;
			r.appendUnique(o.dobj_);
		});

		return(r);
	}

	getReportDobj(vec?) {
		local i, l;

		if((l = getReportObjects(vec)) == nil)
			return(nil);

		if(l.length < 1)
			return(nil);

		for(i = 1; i <= l.length; i++) {
			if(!l[i].ofKind(CollectiveGroup))
				return(l[i]);
		}

		return(l[1]);
	}

	// Returns all the reports for the given action.
	getReportList(act) {
		local r;

		if(_reportManagerReports == nil)
			return(nil);

		r = new Vector(_reportManagerReports.length);

		_reportManagerReports.forEach(function(o) {
			if(!o.action_.ofKind(act))
				return;
			r.append(o);
		});

		return(r);
	}

	// Callback from gAction.
	// This is where we do most of the work, after action resolution
	// has finished.
	afterActionMain() {
		// If we don't have enough reports to summarize, we
		// have nothing to do.
		if(gAction.dobjList_.length < minSummaryLength) {
			return;
		}

		// Kludge to make sure we only do one summary per action.
		_summarizeFlag = true;

		// Actually do the summary.
		gTranscript.summarizeAction(
			function(x) { return(_checkReport(x)); },
			function(vec) {
				// Make sure we're not doing multiple summaries
				// of the same stuff.  This can happen when
				// there are a bunch of objects and we're
				// summarizing ones at the start and end of
				// the report list.  For example, when we're
				// summarizing an inventory listing and our
				// summary applies to items at the start and
				// end but not the ones in the middle.
				if(_summarizeFlag != true)
					return('');
				_summarizeFlag = nil;

				return(summarizeReports(vec));
			}
		);
	}

	// Wrapper for the main checkReport() method.
	_checkReport(report) {
		if(report.action_ != gAction)
			return(nil);

		// We we're the report manager for a specific object or
		// class, check to see if our reports to see if they
		// match it.
		if(reportManagerFor != nil) {
			if((report.dobj_ == nil)
				|| !report.dobj_.ofKind(reportManagerFor))
				return(nil);
		}

		if(checkReport(report) != true)
			return(nil);

		return(true);
	}

	// Decide whether or not we're going to summarize the given report.
	// To be overwritten by instances.
	checkReport(report) { return(true); }

	setReportVector(v) {
		_reportManagerReports = v;
		_summarizedReports = nil;
	}

	// Internal wrapper for the main summary method.  We
	// create a string buffer to hold the summarized action(s),
	// and then call the "real" method.
	summarizeReports(vec) {
		local txt, l;

		setReportVector(vec);

		txt = new StringBuffer();

		l = new Vector(vec.length);
		_reportManagerSummary.forEach(function(s) {
			l.setLength(0);

			vec.forEach(function(o) {
				if(!s.matchAction(o.action_))
					return;
				l.append(o);
			});

			if(l.length > 0)
				s._summarize(l, txt);
		});

		setReportVector(nil);

		return(toString(txt));
	}

	// Returns the total number of reports for the current action
	// (including ones we're not going to summarize).
	totalReports() {
		return((gAction && gAction.dobjList_)
			? gAction.dobjList_.length : 0);
	}

	// Returns the number of reports we're summarizing.
/*
	getSummaryCount() {
		local n;

		if(_summarizedReports != nil)
			return(_summarizedReports);

		if((gAction == nil) || (gAction.dobjList_ == nil))
			return(0);

		n = 0;
		gAction.dobjList_.forEach(function(o) {
			if(o.obj_.reportManager != self)
				return;
			n += 1;
		});

		_summarizedReports = n;

		return(n);
	}
*/
	getSummaryCount() {
		local loc, n;

		if(_summarizedReports != nil)
			return(_summarizedReports);

		if((gAction == nil) || (gAction.dobjList_ == nil))
			return(0);

		if(((loc = _reportManagerReports) == nil) || (loc.length < 1))
			return(0);
		loc = loc[1].dobj_.location;

		n = 0;
		gAction.dobjList_.forEach(function(o) {
			if(o.obj_.reportManager != self)
				return;
			if(o.obj_.location != loc)
				return;
			n += 1;
		});

		_summarizedReports = n;

		return(n);
	}

	// Figure out what announcement text to use.
	// First argument is the StringBuffer we're writing the summary to.
	// Optional second arg is a vector containing the reports we're
	// summarizing.
	reportManagerAnnouncement(txt, vec?, prep?) {
		local obj, t;

		// If we're summarizing ALL the reports, we don't
		// need to add an announcement.
		if((getSummaryCount() == totalReports()) && !prep)
			return;

		if(reportManagerAnnounceText != nil) {
			// If we have an explicit announcement text defined,
			// use it.
			t = reportManagerAnnounceText;
		} else {
			// If we don't have an explicit announcement text
			// defined, we try to get the plural name of the
			// first object from the reports we're summarizing.

			// No objects, bail.
			if((obj = getReportDobj(vec)) == nil)
				return;

			// Get the object's plural name.
			t = obj.pluralName;
		}

		if(prep == true) {
			t = _announcementWithPrep(t, vec);
		}

		// Add the announcement text.  The format is identical
		// to libMessages.announceMultiActionObject(), which
		// is what non-summarized objects would use by default.
		if(t)
			txt.append('<./p0>\n<.announceObj>' + t
				+ ':<./announceObj> <.p0>');
	}

	_announcementWithPrep(t, vec) {
		local obj;

		if((obj = getReportDobj(vec)) == nil)
			return(t);

		obj = obj.location;

		if(obj.ofKind(Actor)) {
			t = '<<t>> carried by <<obj.theNameObj>>';
		} else {
			t = '<<t>> <<obj.objInPrep>> <<obj.theNameObj>>';
		}

		return(t);
	}

	// See if we handle the given action type.
	reportManagerMatchAction(act) {
		local i;

		for(i = 1; i <= _reportManagerSummary.length; i++) {
			if(_reportManagerSummary[i].matchAction(act)) {
				return(true);
			}
		}

		return(nil);
	}
;
