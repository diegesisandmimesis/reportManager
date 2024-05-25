#charset "us-ascii"
//
// reportManagerDefaultReports.t
//
//	Default report classes.
//
//
#include <adv3.h>
#include <en_us.h>

#include "reportManager.h"

class EquivalentLister: SimpleLister
	showListItem(obj, options, pov, infoTab) {
		say(obj.isEquivalent ? obj.aName : obj.theName);
	}
;

class OrLister: SimpleLister
	listSepTwo = " or "
	listSepEnd = ", or "
	longListSepTo = ", or "
	longListSepEnd = "; or "
;

equivalentLister: EquivalentLister;

equivalentOrLister: EquivalentLister, OrLister;

class TakeSummary: ReportSummary
	action = TakeAction

	summarize(data) {
		return('{You/He} take{s} <<equivalentLister
			.makeSimpleList(data.objs)>>. ');
	}
;

class TakeFromSummary: ReportSummary
	action = TakeFromAction

	summarize(data) {
		return('{You/He} take{s} <<equivalentLister
			.makeSimpleList(data.objs)>> from <<gIobj.theName>>. ');
	}
;

class DropSummary: ReportSummary
	action = DropAction

	summarize(data) {
		return('{You/He} drop{s} <<equivalentLister
			.makeSimpleList(data.objs)>>. ');
	}
;

class PutOnSummary: ReportSummary
	action = PutOnAction

	summarize(data) {
		return('{You/He} put{s} <<equivalentLister
			.makeSimpleList(data.objs)>> on <<gIobj.theName>>. ');
	}
;

class PutInSummary: ReportSummary
	action = PutInAction

	summarize(data) {
		return('{You/He} put{s} <<equivalentLister
			.makeSimpleList(data.objs)>> in <<gIobj.theName>>. ');
	}
;

class PutUnderSummary: ReportSummary
	action = PutUnderAction

	summarize(data) {
		return('{You/He} put{s} <<equivalentLister
			.makeSimpleList(data.objs)>> under <<gIobj
			.theName>>. ');
	}
;

class PutBehindSummary: ReportSummary
	action = PutBehindAction

	summarize(data) {
		return('{You/He} put{s} <<equivalentLister
			.makeSimpleList(data.objs)>> behind <<gIobj
			.theName>>. ');
	}
;
/*
class ImplicitTakeSummary: ImplicitSummary
	action = TakeAction

	summarizeImplicit(data) {
		return('first taking <<equivalentLister
			.makeSimpleList(data.objs)>>');
	}
;
*/
