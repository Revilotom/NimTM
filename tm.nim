import os, parseutils, strutils, tables

proc handleError(filename: string, lineNum: int, message = "", charNum = "" ) =
    echo "Syntax error in " & filename & " at line: " & $lineNum & ":" & charNum
    quit message

proc readDefinition(filename: string): (string, seq[string], seq[string], Table[(string, char), (string, char, char)]) = 
    var 
        file = readFile(filename).split("\n")
        lookUp = initTable[(string, char), (string, char, char)]()
        accepting, intermediate, rejecting: seq[string]
        firstState: string
        stateCount: int
        direction: char
        lineNum = 1

    accepting = @[]
    rejecting = @[]
    intermediate = @[]

    let stateLine = file[0].split(" ")

    if stateLine.len != 2:
        handleError(filename, lineNum, "First line should contain 2 fields")
    if stateLine[0] != "states":
        handleError(filename, lineNum, "Expected key word: \"states\" but got \"" & stateLine[0] & "\"")
    if parseInt(stateLine[1], stateCount) == 0:
        handleError(filename, lineNum, "Expected a number after \"states\"")

    for i in countup(1, stateCount):
        lineNum.inc
        let splitted = file[i].split(" ")
        if splitted.len == 2:
            if splitted[1] == "+":
                 accepting.add(splitted[0]) 
            elif splitted[1] == "-":
                rejecting.add(splitted[0])
            else:
                handleError(filename, lineNum, "Expected either \"+\" or  \"-\" but got \"" & splitted[1] & "\"")
        
        elif splitted.len != 1:
            handleError(filename, lineNum, "Number of symbols on line is incorrect")
        else:
            intermediate.add(splitted[0])

        if i == 1:
            firstState = splitted[0]

    lineNum.inc
    let alphabetLine = file[stateCount+1].split(" ") 
    
    if alphabetLine[0] != "alphabet":
        handleError(filename, lineNum, "Expected key word: \"alphabet\" but got \"" & alphabetLine[0] & "\"")

    var alphabetSize: int
    if parseInt(alphabetLine[1], alphabetSize) == 0:
        handleError(filename, lineNum, "Expected a number after \"alphabet\"")

    let alphabet = alphabetLine[2..^1]
    if alphabet.len != alphabetSize:
        handleError(filename, lineNum, "Expected alphabet of length: \"" & $alphabetSize & "\" got: \"" & $alphabet.len & "\"")
    if alphabet.join().len != alphabetSize:
        handleError(filename, lineNum, "Expected character but got string")

    for line in file[stateCount + 2..^1]:

        if line == "":
            continue

        lineNum.inc
        var params = line.split(" ")
        if params.len != 5:
            handleError(filename, lineNum, "Row of transition table should have 5 columns, got " & $params.len)        

        if params[4] == "L":
            direction = 'L'
        elif params[4] == "R":
            direction = 'R'
        elif params[4] == "S":
            direction = 'S'
        else:
            handleError(filename, lineNum, "Expected either \"R\" or  \"L\" or \"S\" but got \"" & params[4] & "\"")

        if params[0] notin intermediate: 
            handleError(filename, lineNum, "\"" & params[0] & "\" is not an intermediate state")
        if params[1] notin alphabet and params[1] != "_":
            handleError(filename, lineNum, "\"" & params[1] & "\" not in alphabet")
        if params[2] notin intermediate and params[2] notin accepting and params[2] notin rejecting: 
            handleError(filename, lineNum, "\"" & params[2] & "\" is not a state")
        if params[3] notin alphabet and params[3] != "_":
            handleError(filename, lineNum, "\"" & params[3] & "\" not in alphabet")

        lookUp[(params[0], char(params[1][0]))] = (params[2], char(params[3][0]), direction)
    
    return (firstState, accepting, rejecting, lookUp)


proc runMachine*(descriptionFile: string, inputFile: string, debug: bool, file: bool): (bool, string) = 
    var 
        tape = inputFile
        oldTape = inputFile
        (firstState, accepting, rejecting, lookUp) = readDefinition(descriptionFile)
        index = 0
        direction: char
        moveCount = 0

    if file:
        tape = inputFile.readFile()
        oldTape = inputFile.readFile()

    while (firstState notin accepting and firstState notin rejecting):

        if index > tape.len - 1:
            tape.add("_")
        if index < 0:
            tape = "_" & tape
            index = 0
        if tape[index] in Whitespace:
            tape[index] = '_'
        
        if debug:
            echo "state: \"" & firstState & "\" input: \"" & tape[index] & "\"" 
            echo tape

        if not lookUp.hasKey((firstState, tape[index])):
            handleError(inputFile, 1, "State \"" & firstState & "\" does not take the input \"" & tape[index] & "\"")

        (firstState, tape[index], direction) = lookUp[(firstState, tape[index])]

        if direction == 'L': 
            index.dec
        elif direction == 'R':
            index.inc

        if direction != 'S':
            moveCount.inc

        
    when isMainModule:
        echo "tape: " & tape 
        echo "length: " & $tape.len  
        echo "head moves: " & $moveCount 

    if firstState in accepting:
        when isMainModule:
            echo "Input was accepted"
        result = (true, tape)
    else:
        when isMainModule:
            echo "Input was rejected"
        result = (false, tape)

when isMainModule:
    let paramCount = paramCount()
    var debug = false

    if paramCount <= 1:
        quit("Please specify a description file as well as an input file.")
    if paramCount == 3:
        if paramStr(3) == "DEBUG":
            debug = true
        else:
            quit("Unknown 3rd parameter \"" & paramStr(3) & "\"")

    if paramCount > 3:
        quit("A maximum of 3 command line arguments are allowed.")

    let descriptionFile = paramStr(1)
    let inputFile = paramStr(2)

    discard runMachine(descriptionFile, inputFile, debug, true)
