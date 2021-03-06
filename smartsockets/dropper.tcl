#
#
#
#

#
# syslog - called in the slave interpreter when tclsyslogd receives messages
#
proc syslog {_message} {
    variable running
    upvar $_message message

    if {!$running} {
	return
    }

    # if we've been told to drop it, drop it
    if {[check_for_drops message]} {
        return ""
    }

    if {![check_for_requires message]} {
        return ""
    }

    set string "$message(clock) / [string trim $message(timestamp)] / $message(host) / $message(program) / $message(priority) / $message(facility)"
    unset message(clock) message(timestamp) message(host) message(program) message(priority) message(facility)

    set string ""
    foreach key [lsort [array names message]] {
	append string ", $key: $message($key)"
    }

    puts "l $string"
}

#
# drop - record patterns for the syslog keyword
#
proc drop {keyword args} {
    variable dropArray

    foreach pattern $args {
	lappend dropArray($keyword) $pattern
    }
}

#
# check_for_drops - return 1 if some drop parameter matches the message
#
proc check_for_drops {_message} {
    variable dropArray
    upvar $_message message

    foreach keyword [array names message] {
        if {![info exists dropArray($keyword)]} {
	    continue
	}

	foreach pattern $dropArray($keyword) {
	    #puts "comparing keyword '$keyword' to pattern '$dropArray($keyword)'"
	    if {[string match $pattern $message($keyword)]} {
	        return 1
	    }
	}
    }

    return 0
}

#
# require - record must-match patterns for syslog keywords
#
proc require {keyword args} {
    variable requireArray

    foreach pattern $args {
        lappend requireArray($keyword) $pattern
    }
}

#
# unrequire - reverse the effect of a previous "require"
#
proc unrequire {keyword args} {
    variable requireArray

    if {![info exists requireArray($keyword)]} {
       return
    }

    foreach pattern $args {
	set where [lsearch $requireArray($keyword) $pattern]
	if {$where < 0} {
	    continue
	}
	set requireArray($keyword) [lreplace $requireArray($keyword) $where $where]
    }
}

#
# check_for_requires - return 1 if all require patterns match the message
#
# pretty identical to check for drops and could be merged with some
# trickery
#
proc check_for_requires {_message} {
    variable requireArray
    upvar $_message message

    # get out quickly if there's nothing to do
    if {[array size requireArray] == 0} {
        return 1
    }

    foreach keyword [array names message] {
        if {![info exists requireArray($keyword)]} {
	    continue
	}

	foreach pattern $requireArray($keyword) {
	    if {![string match $pattern $message($keyword)]} {
	        return 0
	    }
	}
    }
    return 1
}

#
# save - emit a handy thing that can be copied and pasted back in to restore
#        the patterns
#
proc save {} {
    variable dropArray
    variable requireArray

    puts [list load [array get requireArray] [array get dropArray]]
}

#
# load - invoked by pasting the output of save
#
proc load {requireArrayData dropArrayData } {
    variable dropArray
    variable requireArray

    array set requireArray $requireArrayData
    array set dropArray $dropArrayData
}

#
# reset - clear to initial state
#
proc reset {} {
    variable dropArray
    variable requireArray

    unset -nocomplain dropArray requireArray
}

proc stop {} {
    variable running

    set running 0
}

proc start {} {
    variable running

    set running 1
}

start
