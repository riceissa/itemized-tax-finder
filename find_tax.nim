#!/usr/bin/nim r

import std/strformat
import std/parseopt
import std/options
import strutils
import math
import results

type
    TaxedValue = object
        value: float
        tax: float
    History = object
        hist: seq[TaxedValue]

func newHistory(): History =
    return History(hist: @[])

func with(hist: History, v: TaxedValue): History =
    var newlist = hist.hist
    newlist.add(v)
    return History(hist: newlist)

proc `$`(t: TaxedValue): string =
    return fmt"(${t.value} with tax x{t.tax})"

func sum(hist: History, round_before_summing: bool): float =
    var total: float = 0.0
    for v in hist.hist:
        if round_before_summing:
            total += round(v.value * v.tax, 2)
        else:
            total += v.value * v.tax
    return total

proc `$`(hist: History): string =
    result = hist.hist.join(", ")

proc calculate_taxes(amounts: seq[float], total: float, tax_rates: seq[float]): string =
    result = ""
    let tax_multipliers = tax_rates
    for t in tax_multipliers:
        # The tax multiplier must be consistent within a history, so we only
        # define possible_hists once we are inside of the loop.

        # Our history initially has two branches: one that rounds each
        # computation before adding, and one that just keeps all significant
        # digits.
        var possible_hists: seq[History] = @[newHistory()]
        for v in amounts:
            var newhists: seq[History] = @[]
            for hist in possible_hists:
                # Branch out the history based on whether v was taxed or not
                newhists.add(hist.with(TaxedValue(value: v, tax: 1.0)))
                newhists.add(hist.with(TaxedValue(value: v, tax: t)))
            possible_hists = newhists
        for hist in possible_hists:
            for round_before_summing in [true, false]:
                let hist_sum = hist.sum(round_before_summing)
                if abs(hist_sum - total) < 0.01 - 0.00001:
                    result &= "  *"
                    result &= " round before summing? " & (if round_before_summing: "yes" else: "no")
                    result &= fmt", {hist}"
                    result &= fmt": total was {hist_sum}"
                    result &= "\n"

func parseFloatSeq(input: string): Result[seq[float], string] =
    var res: seq[float] = @[]
    for x in input.split(","):
        try:
            res.add(parseFloat(x.strip()))
        except ValueError as e:
            return err(e.msg)
    return ok(res)

func parseSingleFloat(input: string): Result[float, string] =
    try:
        let parsed: float = parseFloat(input.strip())
        return ok(parsed)
    except ValueError as e:
        return err(e.msg)

func parse_input_and_calc(amounts_input, total_input, tax_rates_input: string): Result[string, string] =
    # It would be better if I could have the return type of this function be
    # just string, and then inside this function use do-notation to write
    # something like:
    #     let res = do
    #         amounts <- parseFloatSeq(amounts_input)
    #         total <- parseSingleFloat(total_input)
    #         tax_rates <- parseFloatSeq(tax_rates_input)
    #         ok(calculate_taxes(amounts, total, tax_rates))
    #     if res.isOk:
    #         return res.get()
    #     else:
    #         return res.error()
    # Unfortunately, I don't think this is possible in Nim using the Results
    # package. That's because the early return operator ? will just return out
    # of the *whole function*, rather than just doing an early return out to
    # the "do-block" portion. So I need to have two different functions (this
    # one and unpack_message below) just to contain the ? operator. This
    # function is basically the do-block, and unpack_message is the outer
    # function that uses the do-block's result.
    let amounts = ?parseFloatSeq(amounts_input)
    let total = ?parseSingleFloat(total_input)
    let tax_rates = ?parseFloatSeq(tax_rates_input)
    return ok(calculate_taxes(amounts, total, tax_rates))

func unpack_message(message: Result[string, string]): string =
    if message.isOk:
        return "Results:\n" & message.get()
    else:
        return "Could not parse input:\n" & message.error()

when not defined(js):
    proc main() =
        var amounts_input: string = ""
        var total_input: string = ""
        var tax_rates_input: string = ""
        for kind, key, val in getopt():
            case kind
            of cmdEnd: break
            of cmdShortOption, cmdLongOption:
                if val == "":
                    if key == "amounts":
                        echo "Amounts must be provided using e.g. --amounts=22.09,81.89,16.24"
                    elif key == "total":
                        echo "Total must be provided using e.g. --total=124.13"
                    elif key == "tax-rates":
                        echo "Tax rates must be provided using e.g. --tax-rates=1.100,1.101,1.102,1.103"
                    else:
                        echo "Unknown option: ", key
                else:
                    if key == "amounts":
                        amounts_input = val
                    elif key == "total":
                        total_input = val
                    elif key == "tax-rates":
                        tax_rates_input = val
                    else:
                        echo "Unknown option and value: ", key, ", ", val
            of cmdArgument:
                echo "Unknown argument: ", key, ". Did you accidentally put an extra space between the comma-separated numbers?"
        if amounts_input == "" or total_input == "" or tax_rates_input == "":
            echo "You must pass in all three of amounts, total, and tax rates using the flags (the values are for example) --amounts=22.09,81.89,16.24 --total=124.13 --tax-rates=1.100,1.101,1.102,1.103"
            quit()

        echo unpack_message(parse_input_and_calc(amounts_input, total_input, tax_rates_input))

    if isMainModule:
        main()

when defined(js):
    proc runJS(amounts_input: cstring, total_input: cstring, tax_rates_input: cstring): cstring {.exportc} =
        return cstring(unpack_message(parse_input_and_calc($amounts_input, $total_input, $tax_rates_input)))
