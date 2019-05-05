Function tclfi(txt As String)
'________________________________________________________________
'The purpose of this function is to break apart a CLFI circuit and
'to do some basic checking.  For example does the CLFI contain province
'information
'_________________________________________________________________

/* tclfi */
Dim txtA As String

intLen = Len(txt) // 获取字符串的长度

Select Case intLen // 将字符串的长度作为遍历条件
    Case Is >= 22  // 如果字符串的长度大于22， 执行下面的语句

        Select Case Right(tpatterns(txt), 6)
            Case "AA####"
                Select Case Mid(txt, Len(txt) - 5, 2)
                    Case "DS", "CG"
                        txtZ = Mid(txt, Len(txt) - 13, 11)
                        txtA = Mid(txt, InStr(1, txt, txtZ) - 11, 11)
                    Case Else
                        txtZ = Mid(txt, Len(txt) - 14, 11)
                        txtA = Mid(txt, InStr(1, txt, txtZ) - 11, 11)
                End Select
            Case "A#####", "#A####"
                txtZ = Mid(txt, Len(txt) - 14, 11)
                txtA = Mid(txt, InStr(1, txt, txtZ) - 11, 11)
            Case "AAA###"
                txtZ = Mid(txt, Len(txt) - 13, 11)
                txtA = Mid(txt, InStr(1, txt, txtZ) - 11, 11)
            Case "#AA###", "#AAA##", "A##A##", "AAAA##"
                txtZ = Mid(txt, Len(txt) - 10, 11)
                txtA = Mid(txt, InStr(1, txt, txtZ) - 11, 11)
            Case "##AA##", "AA##A#"
                txtZ = Mid(txt, Len(txt) - 11, 11)
                txtA = Mid(txt, InStr(1, txt, txtZ) - 11, 11)
            Case Else
                txtZ = Right(txt, 11)
                txtA = Mid(txt, InStr(1, txt, txtZ) - 11, 11)  locate(txtZ, txt, 1)

               //  11T1ZFCLGRABBIBMDCLGRAB21DS0
               // InStr(1, txt, txtZ) 代表从字符串的第一位开始算起，txtZ 在 txt 这个字符串中最开始的索引位置。

        End Select
        
        Select Case Mid(txtA, 5, 2)
            Case "NF", "NL", "NS", "PE", "NB", "QC", "PQ", "ON", "MB", "SK", "AB", "BC", "NT", "NU", "YT"
                Select Case Mid(txtZ, 5, 2)
                    Case "NF", "NL", "NS", "PE", "NB", "QC", "PQ", "ON", "MB", "SK", "AB", "BC", "NT", "NU", "YT"
                        
                        Debug.Print "HERE"
                        If Right(txtZ, 1) = "D" Then
                            tclfi = txtZ & ":" & txtA & ":REV"
                        ElseIf Mid(txtA, 9, 2) = "CG" Or Mid(txtA, 9, 2) = "DS" Then
                            tclfi = txtZ & ":" & txtA & ":REV"
                        ElseIf Right(tpatterns(txtA), 1) = "#" Then
                            tclfi = txtZ & ":" & txtA & ":REV"
                        Else
                            tclfi = txtA & ":" & txtZ & ":ORIG"
                        End If
                    
                    Case Else
                            tclfi = "ERROR_PROV"
                End Select
            Case Else
                tclfi = "ERROR_PROV"
        End Select
        
    Case Is < 22 // 如果字符串的长度小于 22， 那么输出错误信息。
        tclfi = "ERROR"
End Select


End Function


/* tpatterns */
Function tpatterns(txt As String)
    
    For i = 1 To Len(txt) // 这是一个循环， 循环变量是 i，从 i 一直循环到字符串的长度
        charCurr = Asc(Mid(txt, i, 1))
        Select Case charCurr
            Case 32
                txtPattern = txtPattern & "_"
            Case 33 To 47, 58 To 64, 91 To 96, 123 To 127
                    txtPattern = txtPattern & "D"
            Case 48 To 57
                    txtPattern = txtPattern & "#"
            Case 65 To 90, 97 To 122, Is > 191
                    txtPattern = txtPattern & "A"
        End Select

tpatterns = txtPattern
    
    Next i
    
End Function


/* tokengen 
第一个参数： 给出的字符串
第二个参数: 取分隔符前后的那一段字符串
第三个参数：分隔符
*/

Function tokengen(txtorig, intToken As Integer, delimiterorig As String)
'_____________________________________________________________________
'The purpose of this function is to be able to pick a specific token
'within a text string, e.g., in "97 ACME STREET WEST"
'=token("97 ACME STREET WEST",3)
'should return "STREET"
'intToken = the token number to return
'if intToken is greater than the total number of tokens then the last token
'is returned by default
'______________________________________________________________________

txt = UCase(txtorig)
delimiter = UCase(delimiterorig)

Select Case intToken
    Case 1
        'Debug.Print tnumspace((txt), " ")
        If tnumspace((txt), (delimiter)) >= 1 Then
            tokengen = Left((txt), tspacenumbergen((txt), 1, (delimiter)) - 1)
        Else
            tokengen = txt
        End If
    Case Else
        If intToken < tnumspace((txt), (delimiter)) + 1 Then
            'the token exists
            tokengen = Mid(txt, tspacenumbergen((txt), intToken - 1, (delimiter)) + 1, tspacenumbergen((txt), intToken, (delimiter)) - tspacenumbergen((txt), intToken - 1, (delimiter)) - 1)
        Else
            tokengen = Right(txt, Len((txt)) - tSpaceRevgen((txt), 1, (delimiter)))
        End If
End Select

End Function

11T1ZFCLGRABBIBMDCLGRAB21DS0


/* tnumspace */

Function tnumspace(txtorig As String, txttofind As String)
'_________________________________________________________________________
'The original intent of this function is to count the number spaces within
'a string.  The function was then generalized to count the occurences of
'a user specified text (txttofind)
'_________________________________________________________________________

txt = tspace(Trim(txtorig))

For i = 1 To Len(txt)
    If Mid(txt, i, 1) = txttofind Then
        intCounter = intCounter + 1
    End If
Next i

tnumspace = intCounter

End Function

/* tspace */
Function tspace(txt As String)

Dim txtCircuit As String
Dim i As Integer

txtCircuit = ""

For i = 1 To Len(txt)
    If Asc(Mid(txt, i, 1)) > 32 Then // 如果当前字符的 ascii 码 大于 32， 那么这个字符是有效的
        txtCircuit = txtCircuit & Mid(txt, i, 1)
        GoTo step2
    End If
    
    If i > 1 Then
            // 如果当前字符是 空格， 前一个字符也是空格，那就什么也不做
            If Asc(Mid(txt, i, 1)) = 32 And Asc(Mid(txt, i - 1, 1)) = 32 Then
                ' do nothing
            Else

                // 1， 如果当前字符不是空格， 那么就将这个字符链接上，
                // 2, 如果当前是空格字符， 但是前一个字符不是空格字符， 那么也将这个空格字符链接上。
                // 总之就是当出现多个连续的空格时， 只保留一个空格。
                txtCircuit = txtCircuit & Mid(txt, i, 1)
            End If
    End If

step2:

Next i
    
tspace = txtCircuit

End Function


/* tspacenumbergen */
Function tspacenumbergen(txtorig As String, intN As Integer, delimiter As String)

'txt = tspace(txtOrig)
txt = txtorig

intcnt = 0
i = 1

Do Until intcnt = intN
    If Asc(Mid(txt, i, 1)) = Asc(delimiter) Then
        intcnt = intcnt + 1
        intPos = i
    End If
    i = i + 1
Loop

    tspacenumbergen = intPos

End Function


/* tSpaceRevgen */
Function tSpaceRevgen(txt, intNum, delimiter As String)

intSpaceNum = 0

For i = Len(txt) To 1 Step -1
    If Asc(Mid(txt, i, 1)) = Asc(delimiter) Then
        intSpaceNum = intSpaceNum + 1
        If intSpaceNum = intNum Then
            tSpaceRevgen = i
            Exit Function
        End If
    End If
Next i
tSpaceRevgen = 0
