#charset "us-ascii"
#include <adv3.h>
#include <en_us.h>

/*
modify CommandTranscript
    summarizeAction(cond, report) {
        local vec = new Vector(8);
        local rpt = reports_;
        local cnt = rpt.length();
        local i;

        for (i = 1 ; i <= cnt && rpt[i].getAction() != gAction ; ++i) ;

        for ( ; ; ++i) {
            local ok;

            ok = nil;
            
            if (i <= cnt) {
                local cur = rpt[i];

                if (cond(cur)) {
                    vec.append(cur);
                    ok = true;
aioSay('\n<<cur.dobj_.name>> @ <<cur.dobj_.location.name>>:  okay 1\n ');
                } else if (cur.ofKind(ImplicitActionAnnouncement)
                         || cur.ofKind(MultiObjectAnnouncement)
                         || cur.ofKind(DefaultCommandReport)
                         || cur.ofKind(ConvBoundaryReport)) {
                    ok = true;
aioSay('\n<<cur.dobj_.name>> @ <<cur.dobj_.location.name>>:  okay 2\n ');
                }
            }

            if (!ok || i == cnt) {
                if (vec.length() > 1) {
                    local insIdx;
                    local txt;
                
                    foreach (local cur in vec) {
                        local idx;
                        
                        idx = rpt.indexOf(cur);

                        rpt.removeElementAt(idx);
                        --i;
                        --cnt;

                        insIdx = idx;

                        for (--idx ;
                             idx > 0
                             && (rpt[idx].ofKind(ImplicitActionAnnouncement)
                                 || rpt[idx].ofKind(DefaultCommandReport)
                                 || rpt[idx].ofKind(ConvBoundaryReport)) ;
                             --idx) {
	aioSay('\nskipping <<rpt[idx].dobj_.name>> @ <<rpt[idx].dobj_.location.name>>\n ');
			}

                        if (idx > 0
                            && rpt[idx].ofKind(MultiObjectAnnouncement)) {
                            rpt.removeElementAt(idx);
                            --i;
                            --cnt;
                            --insIdx;

                            if (idx <= rpt.length()
                                && idx > 1
                                && rpt[idx].ofKind(ConvBeginReport)
                                && rpt[idx-1].ofKind(ConvEndReport)
                                && rpt[idx].actorID == rpt[idx-1].actorID) {
                                rpt.removeRange(idx - 1, idx);
	aioSay('\nskipping <<rpt[idx].dobj_.name>> @ <<rpt[idx].dobj_.location.name>>\n ');
                                i -= 2;
                                cnt -= 2;
                                insIdx -= 2;
                            }
                        }
                    }

aioSay('\nvec:\n ');
vec.forEach(function(o) {
	aioSay('\ncalling with <<o.dobj_.name>> @ <<o.dobj_.location.name>>\n ');
});
                    txt = report(vec);

                    rpt.insertAt(insIdx, new MainCommandReport(txt));
                    ++cnt;
                    ++i;
                }

                if (vec.length() > 0)
                    vec.removeRange(1, vec.length());
            }

            if (i > cnt)
                break;
        }
    }
;
*/
