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
	Const Default_ResizeScalar:Float = 1.5 ' 2.0
	
	' Booleans / Flags:
	Const Default_BigEndianStorage:Bool = False
	
	' Constructor(s) (Public):
	Method New(Size:Int, BigEndianStorage:Bool=Default_BigEndianStorage, Resizable:Bool=True, SizeLimit:Int=NOLIMIT)
		GenerateBuffer(Size)
		
		Self.BigEndianStorage = BigEndianStorage
		Self.ShouldResize = Resizable
		Self.SizeLimit = SizeLimit
	End
	
	Method New(B:DataBuffer, Offset:Int=0, Copy:Bool=False, BigEndianStorage:Bool=Default_BigEndianStorage, Resizable:Bool=True, SizeLimit:Int=NOLIMIT)
		If (Copy) Then
			GenerateBuffer(B)
			
			OwnsBuffer = True
		Else
			Self.Data = B
		Endif
		
		Self._Offset = Offset
		
		Self.BigEndianStorage = BigEndianStorage
		Self.ShouldResize = Resizable
		Self.SizeLimit = SizeLimit
	End
	
	Method New(Path:String, BigEndianStorage:Bool=Default_BigEndianStorage, Async:Bool=False)
		If (Not Async) Then
			Self.Data = DataBuffer.Load(Path)
		Else
			DataBuffer.LoadAsync(Path, Self)
		Endif
		
		Self.BigEndianStorage = BigEndianStorage
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
		Self._Position = Clamp(Input, 0, DataLength)
		
		Return Self._Position
	End
	
	Method Reset:Void()
		Seek()
		
		Return
	End
	
	Method Eof:Int()
		Return (Position >= DataLength)
	End
	
	Method WillOverReach:Bool(Bytes:Int)
		Return (Position+Bytes > DataLength)
	End
	
	Method ReadShort:Int()
		If (BigEndianStorage) Then
			Return NToHS(Super.ReadShort())
		Endif
		
		Return Super.ReadShort()
	End
	
	Method ReadInt:Int()
		If (BigEndianStorage) Then
			Return NToHL(Super.ReadInt())
		Endif
		
		Return Super.ReadInt()
	End
	
	Method ReadFloat:Float()
		If (BigEndianStorage) Then
			Return NToHF(Super.ReadInt())
		Endif
		
		Return Super.ReadFloat()
	End
	
	Method WriteShort:Void(Value:Int)
		If (BigEndianStorage) Then
			Super.WriteShort(HToNS(Value))
		Else
			Super.WriteShort(Value)
		Endif
		
		Return
	End
	
	Method WriteInt:Void(Value:Int)
		If (BigEndianStorage) Then
			Super.WriteInt(HToNL(Value))
		Else
			Super.WriteInt(Value)
		Endif
		
		Return
	End
	
	Method WriteFloat:Void(Value:Float)
		If (BigEndianStorage) Then
			Super.WriteInt(HToNF(Value))
		Else
			Super.WriteFloat(Value)
		Endif
		
		Return
	End
	
	Method WriteAll:Void(Buf:DataBuffer, Offset:Int, Count:Int)
		If (Count+Position > DataLength) Then
			If (ShouldResize) Then
				AutoResize(Count)
			Else
				'Return
			Endif
		Endif
		
		' Call the super-class's implementation.
		Super.WriteAll(Buf, Offset, Count)
		
		Return
	End
	
	Method Read:Int(Buf:DataBuffer, Offset:Int, Count:Int)
		If (WillOverReach(Count)) Then
			Count = Self.BytesLeft
		Endif
		
		#Rem
			For Local Index:= 0 Until Count
				Buf.PokeByte(Offset+Index, Self.Data.PeekByte(Offset+Position+Index))
			Next
		#End
		
		Self.Data.CopyBytes(Self.DataOffset, Buf, Offset, Count)
		
		Self._Position += Count
		
		Return Count
	End
	
	Method Write:Int(Buf:DataBuffer, Offset:Int, Count:Int)
		If (WillOverReach(Count)) Then
			'Count = Max(Length - Position, 0)
			'Count = 0
			
			Return 0
		Endif
		
		#Rem
			For Local Index:= 0 Until Count
				Self.Data.PokeByte(Offset+Position+Index, Buf.PeekByte(Offset+Index))
			Next
		#End
		
		Buf.CopyBytes(Offset, Self.Data, Self.DataOffset, Count)
		
		Self._Position += Count
		
		Return Count
	End
	
	Method TransferTo:Void(S:Stream)
		S.Write(Data, Offset, Position)
		
		Return
	End
	
	Method AutoResize:Bool(MinBytes:Int=0)
		If (Not OwnsBuffer) Then
			Return False
		Endif
		
		Return Resize(Max(Int(Float(Data.Length) * ResizeScalar), MinBytes))
	End
	
	Method SmartResize:Bool(MinBytes:Int)
		If (MinBytes <= DataLength) Then
			Return True
		Endif
		
		Return Resize(MinBytes)
	Endif
	
	Method Resize:Bool(NewSize:Int, Force:Bool=False)
		If (Not OwnsBuffer) Then
			Return False
		Endif
		
		If (SizeLimit <> NOLIMIT) Then
			If (NewSize > SizeLimit) Then
				If (Force) Then
					NewSize = Min(NewSize, SizeLimit)
				Else
					Return False
				Endif
			Endif
		Endif
		
		Data = ResizeBuffer(Data, NewSize, True, True, True)
		
		Return (Data <> Null)
	End
	
	' Call-backs:
	Method OnLoadDataComplete:Void(Data:DataBuffer, Path:String)
		If (Self.Data = Null) Then
			Self.Data = Data
		Endif
		
		Return
	End
	
	' Properties:
	
	' This is currently the same as 'Position'.
	Method Length:Int() Property
		Return Position
	End
	
	' The internal offset/starting point in the 'Data' buffer.
	Method Offset:Int() Property
		Return Self._Offset
	End
	
	' The number of bytes into the buffer this stream is.
	Method Position:Int() Property
		Return Self._Position
	End
	
	' The overall length of the 'Data' buffer. (Taking 'Offset' into account)
	Method DataLength:Int() Property
		Return (Data.Length - Offset)
	End
	
	' The real position in the 'Data' buffer. (After 'Offset')
	Method DataOffset:Int() Property
		Return (Offset+Position)
	End
	
	' The number of bytes left in 'Data'.
	Method BytesLeft:Int() Property
		Return Max(DataLength - DataOffset, 0)
	End
	
	' This may be used for asynchronous buffer-loading.
	Method DataReady:Bool() Property
		Return (Data <> Null)
	End
	
	' Fields:
	
	' The internal I/O buffer.
	Field Data:DataBuffer
	
	' Please use the corresponding properties when possible:
	
	' This acts as an internal offset inside the 'Data' buffer.
	Field _Offset:Int
	
	' The (Local) position of the stream.
	Field _Position:Int
	
	' The internal buffer's size-limit. (Used when resizing)
	Field SizeLimit:Int = NOLIMIT
	
	' A floating-point scalar used when a resize-operation occurs.
	' Numbers will be rounded as the hardware sees fit. (Usually rounds down)
	Field ResizeScalar:Float = Default_ResizeScalar
	
	' Booleans / Flags:
	
	' This may be used to toggle resizing the internal buffer.
	Field ShouldResize:Bool
	
	' This specifies if big-endian byte-order should be used.
	Field BigEndianStorage:Bool
	
	' This specifies if this stream owns the internal buffer.
	Field OwnsBuffer:Bool
End