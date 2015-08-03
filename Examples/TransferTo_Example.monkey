Strict

Public

' Imports:
Import publicdatastream

Import time

Import brl.datastream

' Functions:
Function Main:Int()
	' Constant variable(s):
	Const Numbers:= 2048
	
	' Local variable(s):
	Local StartTime:= Millisecs()
	
	For Local Test:= 1 To 8192
		' Local variable(s):
		Local S:= New PublicDataStream(Numbers*4) ' SizeOf_Integer
		Local B:= New DataBuffer(S.DataLength)
		Local D:= New DataStream(B)
		
		For Local I:= 1 To Numbers
			S.WriteInt(I)
		Next
		
		S.TransferTo(D)
		D.Seek(0)
		
		S.Close()
		
		Local Number:Int = 1
		
		While (Not D.Eof())
			If (D.ReadInt() <> Number) Then
				Print("Critical failure.")
				
				Return -1
			Endif
			
			Number += 1
		Wend
		
		D.Close()
		B.Discard()
	Next
	
	Local TimeTaken:= (Millisecs()-StartTime)
	
	Print("That took " + TimeTaken + "ms.")
	
	' Return the default response.
	Return 0
End