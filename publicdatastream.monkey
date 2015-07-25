Strict

Public

' Preprocessor related:
' Nothing so far.

' Imports (Public):
Import byteorder

' BRL:
Import brl.stream

' Imports (Private):
Private

Import util

' BRL:
Import brl.databuffer

Public

' Classes:
Class PublicDataStream Extends Stream Implements IOnLoadDataComplete
	' Constant variable(s):
	Const NOLIMIT:Int = 0
	
	' Defaults:
	Const Default_BigEndianStorage:Bool = False
	
	' Constructor(s) (Public):
	Method New(Size:Int, FixByteOrder:Bool=Default_BigEndianStorage, Resizable:Bool=True, SizeLimit:Int=NOLIMIT)
		GenerateBuffer(Size)
		
		Self.FixByteOrder = FixByteOrder
		Self.ShouldResize = Resizable
		Self.SizeLimit = SizeLimit
	End
	
	Method New(B:DataBuffer, Offset:Int=0, Copy:Bool=False, FixByteOrder:Bool=Default_BigEndianStorage, Resizable:Bool=True, SizeLimit:Int=NOLIMIT)
		If (Copy) Then
			GenerateBuffer(B)
			
			OwnsBuffer = True
		Else
			Self.Data = B
		Endif
		
		Self._Offset = Offset
		
		Self.FixByteOrder = FixByteOrder
		Self.ShouldResize = Resizable
		Self.SizeLimit = SizeLimit
	End
	
	Method New(Path:String, FixByteOrder:Bool=Default_BigEndianStorage, Async:Bool=False)
		If (Not Async) Then
			Self.Data = DataBuffer.Load(Path)
		Else
			DataBuffer.LoadAsync(Path, Self)
		Endif
		
		Self.FixByteOrder = FixByteOrder
	End
	
	' Constructor(s) (Protected):
	Protected
	
	Method GenerateBuffer:Void(Size:Int)
		Self.Data = New DataBuffer(Size)
		
		Return
	End
	
	' This will copy the contents of 'B' into an internally managed buffer.
	Method GenerateBuffer:Void(B:DataBuffer)
		GenerateBuffer(B.Length)
		
		B.CopyBytes(0, Data, 0, Data.Length)
		
		Return
	End
	
	Public
	
	' Destructor(s):
	Method FreeBuffer:Void(DiscardBuffer:Bool=True)
		If (Data <> Null) Then
			If (DiscardBuffer) Then
				Data.Discard()
			Endif
			
			Data = Null
		Endif
		
		OwnsBuffer = False
		
		Return
	End
	
	Method Close:Void()
		FreeBuffer(OwnsBuffer)
		
		Self._Position = 0
		Self._Offset = 0
		
		Return
	End
	
	' Methods:
	Method Seek:Int(Input:Int=0)
		Self._Position = Clamp(Input, 0, (Length-1))
		
		Return Self._Position
	End
	
	Method Reset:Void()
		Seek()
		
		Return
	End
	
	Method Eof:Int()
		Return (Position >= Length)
	End
	
	Method WillOverReach:Bool(Bytes:Int)
		Return (Position+Bytes > Length)
	End
	
	Method ReadShort:Int()
		If (FixByteOrder) Then
			Return NToHS(Super.ReadShort())
		Endif
		
		Return Super.ReadShort()
	End
	
	Method ReadInt:Int()
		If (FixByteOrder) Then
			Return NToHL(Super.ReadInt())
		Endif
		
		Return Super.ReadInt()
	End
	
	Method ReadFloat:Float()
		If (FixByteOrder) Then
			Return NToHF(Super.ReadFloat())
		Endif
		
		Return Super.ReadFloat()
	End
	
	Method WriteShort:Void(Value:Int)
		If (FixByteOrder) Then
			Super.WriteShort(HToNS(Value))
		Else
			Super.WriteShort(Value)
		Endif
		
		Return
	End
	
	Method WriteInt:Void(Value:Int)
		If (FixByteOrder) Then
			Super.WriteInt(HToNL(Value))
		Else
			Super.WriteInt(Value)
		Endif
		
		Return
	End
	
	Method WriteFloat:Void(Value:Float)
		If (FixByteOrder) Then
			Super.WriteInt(HToNF(Value))
		Else
			Super.WriteFloat(Value)
		Endif
		
		Return
	End
	
	Method WriteAll:Void(Buf:DataBuffer, Offset:Int, Count:Int)
		Local WriteResponse:Bool = True
		
		If (Count+Position > Data.Length) Then
			If (ShouldResize) Then
				Local NewSize:= (Data.Length * 2)
				
				If ((NewSize < SizeLimit Or SizeLimit = NOLIMIT)) Then
					Data = ResizeBuffer(Data, NewSize, OwnsBuffer)
				Else
					'WriteResponse = False
				Endif
			Else
				'WriteResponse = False
			Endif
		Endif
		
		' Call the super-class's implementation.
		If (WriteResponse) Then
			Super.WriteAll(Buf, Offset, Count)
		Endif
		
		Return
	End
	
	Method Read:Int(Buf:DataBuffer, Offset:Int, Count:Int)
		If (Position + Count > Length) Then
			Count = Max(Length - Position, 0)
		Endif
		
		For Local Index:= 0 Until Count
			Buf.PokeByte(Offset+Index, Self.Data.PeekByte(Offset+Position+Index))
		Next
		
		Self._Position += Count
		
		Return Count
	End
	
	Method Write:Int(Buf:DataBuffer, Offset:Int, Count:Int)
		If (Position + Count > Length) Then
			'Count = Max(Length - Position, 0)
			Count = 0
		Endif
		
		For Local Index:= 0 Until Count
			Self.Data.PokeByte(Offset+Position+Index, Buf.PeekByte(Offset+Index))
		Next
		
		Self._Position += Count
		
		Return Count
	End
	
	' Call-backs:
	Method OnLoadDataComplete:Void(Data:DataBuffer, Path:String)
		If (Self.Data = Null) Then
			Self.Data = Data
		Endif
		
		Return
	End
	
	' Properties:
	Method Length:Int() Property
		Return (Data.Length - Offset)
	End
	
	Method Offset:Int() Property
		Return Self._Offset
	End
	
	Method Position:Int() Property
		Return Self._Position
	End
	
	Method BytesLeft:Int() Property
		Return Max(Length - Position, 0)
	End
	
	Method DataReady:Bool() Property
		Return (Data <> Null)
	End
	
	' Fields:
	Field Data:DataBuffer
	
	Field _Offset:Int
	Field _Position:Int
	
	Field SizeLimit:Int = NOLIMIT
	
	' Booleans / Flags:
	Field ShouldResize:Bool
	Field FixByteOrder:Bool
	Field OwnsBuffer:Bool
End