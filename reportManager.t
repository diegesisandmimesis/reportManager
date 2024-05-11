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
//	You want to merge the ball reports into a single message, but you
//	don't want to also merge the pebble description, so you can't just
//	always summarize multiple >EXAMINE reports together.
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
//	summarizing.  This involves definition a number of things on
//	the report manager:
//
//		reportManagerActions
//			a list of the actions the report manager will
//			handle.  example:
//
//			reportManagerActions = static [ Examine action ]
//
//		checkReport(report)
//			a method that accepts a report instance as its
//			only argument and returns boolean true if the
//			report manager wants to summarize the report,
//			nil otherwise
//
//		summarizeReport(act, vec, txt)
//			a method that actually writes the summary
//
//			arguments are:  the action type;  a vector
//			containing the reports being summarized;  and
//			the StringBuffer to write the summary to
//
//
//	An example:
//
//		ballReportManager: ReportManager
//			// We only summarize >EXAMINE reports
//			reportManagerActions = static [ ExamineAction ]
//
//			// We only summarize reports involving Ball instances.
//			checkReport(report) {
//				return((report.dobj_ != nil)
//					&& report.dobj_.ofKind(Ball));
//			}
//
//			// Actually summarize the reports.
//			summarizeReport(act, vec, txt) {
//				local l;
//
//				// Make sure we have data to summarize.
//				if((l = getReporObjects()) == nil)
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

// Remember the direct object in every command report.
// This approach is from Eric Eve's "Manipulating the Transcript"
//	https://tads.org/t3doc/doc/techman/t3transcript.htm
modify CommandReport
	dobj_ = nil

	construct() {
		inherited();
		dobj_ = gDobj;
	}
;

// Modify TAction to check to see if any matching objects have report
// managers.
modify TAction
	afterActionMain() {
		inherited();
		if(parentAction == nil)
			reportManagerAfterAction();
	}

	reportManagerAfterAction() {
		local l;

		// If we don't have any objects, we have nothing to do.
		// Should never happen.
		if(dobjList_ == nil)
			return;

		// Vector to keep track of our matches.
		l = new Vector(dobjList_.length);

		// Go through the object list.
		dobjList_.forEach(function(o) {
			// If the object doesn't have a report manager, bail.
			if(o.obj_.reportManager == nil)
				return;

			// Check to see if the report manager handles this
			// kind of action.
			if(!o.obj_.reportManager.reportManagerMatchAction(self))
				return;

			// Remember this report manager.
			l.appendUnique(o.obj_.reportManager);
		});

		// Ping all of the report managers we got above.
		l.forEach(function(o) { o.afterActionMain(); });
	}
;

// Modify Thing to have a property for the optional report manager.
modify Thing
	reportManager = nil
;

// The report manager object.
class ReportManager: object
	// Minimum number of reports needed to summarize.
	// If an action doesn't produce at least this many, we won't
	// do anything.
	minSummaryLength = 2

	// List of actions we summarize.
	reportManagerActions = perInstance(new Vector())

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

	// Property to hold the reports for a specific action.  Set
	// by the _summarizeReports() wrapper, we just store this so
	// we don't have to juggle it as an argument for the summary
	// methods.
	_reportManagerReports = nil

	addReportManagerAction(obj) {
		if((obj == nil) || !obj.ofKind(Action))
			return;

		reportManagerActions.appendUnique(obj);
	}

	// Returns a list of all the objects in the reports we're
	// summarizing.
	getReportObjects() {
		local r;

		if(_reportManagerReports == nil)
			return(nil);

		r = new Vector(_reportManagerReports.length);

		_reportManagerReports.forEach(function(o) {
			if(o.dobj_ == nil)
				return;
			r.appendUnique(o.dobj_);
		});

		return(r);
	}

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

		// Actually do the summary.
		gTranscript.summarizeAction(
			function(x) { return(_checkReport(x)); },
			function(vec) {
				return(_summarizeAllReports(vec));
			}
		);
	}

	// Wrapper for the main checkReport() method.
	_checkReport(report) {
		if(report.action_ != gAction)
			return(nil);

		if(checkReport(report) != true)
			return(nil);

		return(true);
	}

	// Decide whether or not we're going to summarize the given report.
	checkReport(report) { return(true); }

	// Returns the total number of reports for the current action
	// (including ones we're not going to summarize).
	totalReports() {
		return((gAction && gAction.dobjList_)
			? gAction.dobjList_.length
			: 0);
	}

	// Returns the number of reports we're summarizing.
	summarizedReports() {
		local n;

		if((gAction == nil) || (gAction.dobjList_ == nil))
			return(0);

		n = 0;
		gAction.dobjList_.forEach(function(o) {
			if(o.obj_.reportManager != self)
				return;
			n += 1;
		});

		return(n);
	}

	// Internal wrapper for the main summary method.  We
	// create a string buffer to hold the summarized action(s),
	// and then call the "real" method.
	_summarizeAllReports(vec) {
		local txt, l;

		_reportManagerReports = vec;

		txt = new StringBuffer();

		l = new Vector(vec.length);
		reportManagerActions.forEach(function(act) {
			l.setLength(0);

			vec.forEach(function(o) {
				if(!o.action_.ofKind(act))
					return;
				l.append(o);
			});

			if(l.length > 0)
				_summarizeReport(act, l, txt);
		});

		_reportManagerReports = nil;

		return(toString(txt));
	}

	_summarizeReport(act, lst, txt) {
		// If we're not summarizing ALL the reports, we add
		// some announcement text to the start of our summary.
		if(summarizedReports() != totalReports()) {
			reportManagerAnnouncement(txt);
		}

		summarizeReport(act, lst, txt);

	}

	// Figure out what announcement text to use.
	// Argument is the StringBuffer we're writing the summary to.
	reportManagerAnnouncement(txt) {
		local obj, t;

		// We always append a "big" results separator to
		// the text.  By default this will be "<.p>"
		//txt.append(libMessages.complexResultsSeparator);

		if(reportManagerAnnounceText != nil) {
			// If we have an explicit announcement text defined,
			// use it.
			t = reportManagerAnnounceText;
		} else {
			// If we don't have an explicit announcement text
			// defined, we try to get the plural name of the
			// first object from the reports we're summarizing.

			// No objects, bail.
			if((obj = getReportObjects()) == nil)
				return;

			// No first object, bail.
			if((obj = obj[1]) == nil)
				return;

			// Get the object's plural name.
			t = obj.pluralName;
		}

		// Add the announcement text.  The format is identical
		// to libMessages.announceMultiActionObject(), which
		// is what non-summarized objects would use by default.
		if(t)
			txt.append('<./p0>\n<.announceObj>' + t
				+ ':<./announceObj> <.p0>');
	}

	// Stub method, to be overwritten by subclasses/instances.
	// This is where the actual summary logic will live.
	summarizeReport(act, vec, txt) {}

	// See if we handle the given action type.
	reportManagerMatchAction(act) {
		local i;

		for(i = 1; i <= reportManagerActions.length; i++) {
			if(act.ofKind(reportManagerActions[i])) {
				return(true);
			}
		}

		return(nil);
	}
;
