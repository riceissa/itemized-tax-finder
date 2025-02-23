#!/usr/bin/nim r

import std/strformat
import strutils
import math

type
    TaxedValue = object
        value: float
        tax: float
    History = object
        hist: seq[TaxedValue]
        round_before_summing: bool

func newHistory(round_before_summing: bool): History =
    return History(hist: @[], round_before_summing: round_before_summing)

func with(hist: History, v: TaxedValue): History =
    var newlist = hist.hist
    newlist.add(v)
    return History(hist: newlist, round_before_summing: hist.round_before_summing)

proc `$`(t: TaxedValue): string =
    return fmt"(${t.value} with tax x{t.tax})"

func sum(hist: History): float =
    var total: float = 0.0
    for v in hist.hist:
        if hist.round_before_summing:
            total += round(v.value * v.tax, 2)
        else:
            total += v.value * v.tax
    return total

proc `$`(hist: History): string =
    result = fmt"round_before_summing={hist.round_before_summing}, "
    result &= hist.hist.join(", ")
    result &= fmt": total was {hist.sum()}"

proc calculate_taxes(amounts: seq[float], total: float): string =
    result = ""
    let tax_multipliers = [1.100, 1.101, 1.102, 1.103]
    for t in tax_multipliers:
        # The tax multiplier must be consistent within a history, so we only
        # define possible_hists once we are inside of the loop.

        # Our history initially has two branches: one that rounds each
        # computation before adding, and one that just keeps all significant
        # digits.
        var possible_hists: seq[History] = @[newHistory(true), newHistory(false)]
        for v in amounts:
            var newhists: seq[History] = @[]
            for hist in possible_hists:
                # Branch out the history based on whether v was taxed or not
                newhists.add(hist.with(TaxedValue(value: v, tax: 1.0)))
                newhists.add(hist.with(TaxedValue(value: v, tax: t)))
            possible_hists = newhists
        for hist in possible_hists:
            let hist_sum = hist.sum()
            if abs(hist_sum - total) < 0.01 - 0.00001:
                result &= fmt"  * {hist}" & "\n"

proc main() =
    # Values to be modified by the user:
    # 1. amounts: This is the list of individual amounts, NOT including tax.
    let amounts = @[22.09, 81.89, 16.24]

    # 2. totalAmount: This is the amount that was actually paid, and includes tax.
    #    For example, it might be the amount that appears on your credit card
    #    statement.
    let total = 124.13

    # Nothing else in this file should be edited by the user.

    echo ""
    echo "====================================="
    echo "Results:"
    echo ""
    echo calculate_taxes(amounts, total)

proc runJS(amounts: seq[float], total: float): cstring {.exportc} =
    let message = "Results:\n" & calculate_taxes(amounts, total)
    return cstring(message)

if isMainModule:
    main()
