#charset "us-ascii"
//
// reportManagerImplicit.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "reportManager.h"

class ImplicitSummary: ReportSummary
	isImplicit = true

	matchImplicitReport(report) {
		if((report == nil)
			|| !report.ofKind(ImplicitActionAnnouncement))
			return(nil);

		if(report.isFailure != isFailure)
			return(nil);

		return(matchAction(report.action_));
	}

	_summarizeImplicit(vec, data, act) {
		local i, idx, r, txt;

		if((idx = data.vec.indexWhich({
			x: x.ofKind(ImplicitActionAnnouncement)
		})) == nil)
			return;

		r = data.vec[idx];

		if((idx = vec.indexOf(r)) == nil)
			return;

		for(i = 1; i <= data.vec.length; i++) {
			if(data.vec[i].action_.ofKind(act)) {
				vec.removeElement(data.vec[i]);
			}
		}


		txt = summarizeImplicit(data);
		r.messageText_ = '<./p0>\n<.assume><<txt>><./assume>\n';
		r.messageProp_ = nil;

		vec.insertAt(idx, r);
	}
;

class ImplicitTakeSummary: ImplicitSummary
	action = TakeAction

	summarizeImplicit(data) {
		return('first taking <<equivalentLister
			.makeSimpleList(data.objs)>>');
	}
;

modify transcriptManager
	_implicitSummaries = perInstance(new Vector())
	_implicitActionList = nil

	defaultImplicitSummaries = static [
		ImplicitTakeSummary
	]

	initializeTranscriptManager() {
		inherited();
		initializeTranscriptManagerImplicitSummaries();
	}

	initializeTranscriptManagerImplicitSummaries() {
		local i, l;

		if(defaultImplicitSummaries == nil)
			return;

		if(!defaultImplicitSummaries.ofKind(Collection))
			defaultImplicitSummaries = [ defaultImplicitSummaries ];
			
		l = new Vector(defaultImplicitSummaries.length);

		defaultImplicitSummaries.forEach(function(o) {
			for(i = 1; i <= _implicitSummaries.length; i++) {
				if(_implicitSummaries[i].ofKind(o))
					return;
			}
			l.appendUnique(o);
		});

		l.forEach(function(o) {
			addImplicitSummary(o.createInstance());
		});
	}

	addImplicitSummary(obj) {
		if((obj == nil) || !obj.ofKind(ImplicitSummary))
			return(nil);

		_implicitSummaries.append(obj);

		// When we add a new summary, make sure we have to
		// re-construct the action list when needed.
		_implicitActionList = nil;

		return(true);
	}

	getImplicitActionList() {
		if(_implicitActionList == nil) {
			_implicitActionList
				= new Vector(_implicitSummaries.length);
			_implicitSummaries.forEach({
				x: _implicitActionList.append(x.action)
			});
		}

		return(_implicitActionList);
	}

	getImplicitAction(act) {
		local i, l;

		l = getImplicitActionList();
		for(i = 1; i <= l.length; i++) {
			if(act.ofKind(l[i]))
				return(l[i]);
		}

		return(nil);
	}

	getNextImplicitActionAnnouncement(vec, idx?) {
		local i;

		if(idx == nil)
			idx = 1;

		for(i = idx; i <= vec.length; i++) {
			if(vec[i].ofKind(ImplicitActionAnnouncement))
				return(i);
		}

		return(nil);
	}

	summarizeImplicit(vec) {
		local act, ar, d, i, ia, idx, iv, ivIdx, l, s, v;

		// Make sure we have at least one implicit action.
		if((idx = getNextImplicitActionAnnouncement(vec)) == nil)
			return;

		if(vec.countWhich({
			x : x.ofKind(ImplicitActionAnnouncement)
		}) < 2)
			return;

		// Vector for our implicit actions sorted by action type,
		// and a vector for the actions.
		v = new Vector(vec.length);

		ia = getImplicitActionList();

		l = new Vector(ia.length);

		while((idx != nil) && (idx < vec.length)) {
			if((act = getImplicitAction(vec[idx].action_)) != nil) {
				ar = TranscriptModifier.findMultiObjectAnnouncementEndpoints(vec, idx);
				iv = new Vector(ar[2] - ar[1] + 1).copyFrom(vec,
					ar[1], 1, ar[2] - ar[1] + 1);

				if(iv.indexWhich({x: x.isFailure}) == nil) {
					if((ivIdx = l.indexOf(act)) == nil) {
						l.appendUnique(act);
						ivIdx = l.length;
						v.append(new Vector());
					}
					v[ivIdx].appendAll(iv.subset({
						x: !x.ofKind(PlaceholderReport)
					}));
				}

				idx = ar[2] + 1;
			}

			idx = getNextImplicitActionAnnouncement(vec, idx);
		}
		
		v.forEach(function(o) {
			for(i = 1; i <= _implicitSummaries.length; i++) {
				s = _implicitSummaries[i];
				idx = o.indexWhich({
					x: x.ofKind(ImplicitActionAnnouncement)
				});
				if(s.matchAction(o[idx].action_)) {
					d = new ReportSummaryData(o);
					s._summarizeImplicit(vec, d,
						getImplicitAction(o[idx].action_));
				}
			}
		});
	}
;
