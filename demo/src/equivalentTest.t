#charset "us-ascii"
//
// equivalentTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the reportManager library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f equivalentTest.t3m
//
// ...or the equivalent, depending on what TADS development environment
// you're using.
//
// This "game" is distributed under the MIT License, see LICENSE.txt
// for details.
//
#include <adv3.h>
#include <en_us.h>

#include "reportManager.h"

versionInfo: GameID;
gameMain: GameMainDef initialPlayerChar = me;

class Pebble: Thing '(small) (round) pebble*pebbles' 'pebble'
	"A small, round pebble. "
	isEquivalent = true
;

pebbleReportManager: ReportManager
	reportManagerFor = Pebble
;
+ReportSummary
	action = ExamineAction
	summarize(vec, txt) {
		local l;

		if((l = getReportObjects()) == nil)
			return;

		txt.append('It\'s <<spellInt(l.length)>> small, round
			pebbles. ');
	}
;

startRoom: Room 'Void' "This is a featureless void.";
+me: Person;
+Pebble;
+Pebble;
+Pebble;
+Thing '(ordinary) rock' 'rock' "An ordinary rock. ";
