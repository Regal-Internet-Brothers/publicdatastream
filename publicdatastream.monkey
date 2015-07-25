Strict

Public

' Preprocessor related:
#PUBLIC_DATA_STREAM_ALLOW_CONVERSION = True

' Imports (Public):

' BRL:
Import brl.stream

' ImmutableOctet:
Import byteorder

' Imports (Private):
Private

' BRL:
Import brl.databuffer

#If PUBLIC_DATA_STREAM_ALLOW_CONVERSION
	Import brl.datastream
#End

Public

' Classes:
Class PublicDataStream Extends Stream
	' Constant variable(s):
	Const NOLIMIT:Int = 0
	
	' Defaults:
	Const Default_BigEndianStorage:Bool = False
	
	' Constructor(s) (Public):
	Method New(ShouldResize:Bool, Path:String="", SizeLimit:Int=NOLIMIT, BigEndianStorage:Bool=Default_BigEndianStorage)
		Construct(ShouldResize, Path, SizeLimit, BigEndianStorage)
	End
	
	Method New(BufferSize:Int, ShouldResize:Bool=False, Path:String="", SizeLimit:Int=NOLIMIT, BigEndianStorage:Bool=Default_BigEndianStorage)
		Construct(New DataBuffer(BufferSize), 0, 0, ShouldResize, Path, SizeLimit, BigEndianStorage)
	End
	
	Method New(Buffer:DataBuffer, Offset:Int=0, ShouldResize:Bool=False, Path:String="", SizeLimit:Int=NOLIMIT, BigEndianStorage:Bool=Default_BigEndianStorage)
		Construct(Buffer, Offset, ShouldResize, Path, SizeLimit, BigEndianStorage)
	End
	
	Method New(Buffer:DataBuffer, Offset:Int, Length:Int, ShouldResize:Bool=False, Path:String="", SizeLimit:Int=NOLIMIT, BigEndianStorage:Bool=Default_BigEndianStorage)
		Construct(Buffer, Offset, Length, ShouldResize, Path, SizeLimit, BigEndianStorage)
	End
	
	Method New(O:Object, ShouldResize:Bool=True, BigEndianStorage:Bool=Default_BigEndianStorage)
		Construct(O, ShouldResize, BigEndianStorage)
	End
	
	Method New(Path:String, BigEndianStorage:Bool=Default_BigEndianStorage)
		Construct(Null, 0, False, Path, BigEndianStorage)
	End
	
	' This is here for the sake of inheriting classes:
	Method Construct:PublicDataStream(O:Object, ShouldResize:Bool=True, BigEndianStorage:Bool=Default_BigEndianStorage)
		Return Null
	End
	
	Method Construct:PublicDataStream(ShouldResize:Bool=True, Path:String="", SizeLimit:Int=NOLIMIT, BigEndianStorage:Bool=Default_BigEndianStorage)
		' Local variable(s):
		Local B:DataBuffer = Null
		
		If (Self._Buffer = Null) Then
			If (Not Path.Length()) Then
				B = New DataBuffer(1024)
			Endif
		Endif
		
		Return Construct(B, 0, 0, ShouldResize, Path, SizeLimit, BigEndianStorage)
	End
	
	Method Construct:PublicDataStream(Data:DataBuffer, Offset:Int, ShouldResize:Bool=False, Path:String="", SizeLimit:Int=NOLIMIT, BigEndianStorage:Bool=Default_BigEndianStorage)
		Return Construct(Data, Offset, Data.Length, ShouldResize, Path, SizeLimit, BigEndianStorage)
	End
	
	Method Construct:PublicDataStream(Data:DataBuffer, Offset:Int=0, Length:Int=0, ShouldResize:Bool=False, Path:String="", SizeLimit:Int=NOLIMIT, BigEndianStorage:Bool=Default_BigEndianStorage)
		If (Self._Buffer = Null) Then
			If (Data = Null And Path.Length() > 0) Then
				Data = DataBuffer.Load(Path)
			Endif
			
			Self._Buffer = Data
		Endif
		
		If (Length = 0 And Self._Buffer <> Null) Then
			Length = Self._Buffer.Length()
		Endif
		
		Self._Offset = Offset
		Self._Position = 0
		Self._Length = Max(Length-Offset, 0)
		Self.ShouldResize = ShouldResize
		Self.Path = Path
		
		Self.KeepBuffer = False
		Self.BigEndianStorage = BigEndianStorage
		
		Return Self
	End
	
	' Constructor(s) (Private):
	Private
	
	' Nothing so far.
	
	Public
	
	' Destructor(s):
	Method FreeBuffer:Void()
		If (Self.KeepBuffer) Then Return
		
		If (Self._Buffer <> Null) Then
			Self._Buffer = Null
		Endif
		
		Return
	End
	
	Method Close:Void()
		FreeBuffer()
		
		' Integers:
		Self._Position = 0
		Self._Length = 0
		Self._Offset = 0
		
		' Strings:
		Self.Path = ""
		
		' Flags:
		Self.ShouldResize = False
		Self.BigEndianStorage = Default_BigEndianStorage
		
		Return
	End

	' Methods (Public):
	Method ReadShort:Int()
		' Local variable(s):
		Local Data:= Super.ReadShort()
		
		If (BigEndianStorage) Then
			Data = NToHS(Data)
		Endif
		
		Return Data
	End
	
	Method ReadInt:Int()
		' Local variable(s):
		Local Data:= Super.ReadInt()
		
		If (BigEndianStorage) Then
			Data = NToHL(Data)
		Endif
		
		Return Data
	End
	
	Method ReadFloat:Float()
		' Local variable(s):
		Local Data:Float = 0.0
		
		If (BigEndianStorage) Then
			Data = NToHF(Super.ReadInt())
		Else
			Data = Super.ReadFloat()
		Endif
		
		Return Data
	End
	
	Method WriteShort:Void(Value:Int)
		If (BigEndianStorage) Then
			Value = HToNS(Value)
		Endif
		
		' Call the super-class's implementation.
		Super.WriteShort(Value)
		
		Return
	End
	
	Method WriteInt:Void(Value:Int)
		If (BigEndianStorage) Then
			Value = HToNL(Value)
		Endif
		
		' Call the super-class's implementation.
		Super.WriteInt(Value)
		
		Return
	End
	
	Method WriteFloat:Void(Value:Float)
		' Call the evaluated write command.
		If (BigEndianStorage) Then
			Super.WriteInt(HToNF(Value))
		Else
			Super.WriteFloat(Value)
		Endif
		
		Return
	End
	
	Method WriteAll:Void(Buf:DataBuffer, Offset:Int, Count:Int)
		Local WriteResponse:Bool = True
		
		If (Count+Position > Buffer.Length()) Then
			If (ShouldResize) Then
				If ((Buffer.Length()*2 < SizeLimit Or SizeLimit = NOLIMIT)) Then
					Buffer = ResizeBuffer(Buffer, Buffer.Length()*2)
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
	
	Method ReadAll:Void(Buffer:DataBuffer, Offset:Int, Count:Int)		
		' Call the super-class's implementation.
		Super.ReadAll(Buffer, Offset, Count)
		
		Return
	End
	
	#If PUBLIC_DATA_STREAM_ALLOW_CONVERSION
		Method ToDataStream:DataStream(CloseThis:Bool=True)
			Local DS:DataStream
			
			DS = New DataStream(Buffer, Position, Length)
			
			If (CloseThis) Then Close()
			
			Return DS
		End
	#End
	
	Method Seek:Int(Input:Int=0)
		Self._Position = Clamp(Input, 0, Self._Length-1)
		
		Return Self._Position
	End
	
	Method Eof:Int()
		Return (_Position >= _Length)
	End
	
	Method WillOverReach:Bool(Bytes:Int)
		Return (_Position+Bytes > _Length)
	End
	
	Method Read:Int(Buf:DataBuffer, Offset:Int, Count:Int)
		If (Self._Position + Count > Self._Length) Then
			Count = Max(Self._Length - Self._Position, 0)
		Endif
		
		For Local Index:= 0 Until Count
			Buf.PokeByte(Offset+Index, Self._Buffer.PeekByte(Self._Offset+Self._Position+Index))
		Next
		
		Self._Position += Count
		
		Return Count
	End
	
	Method Write:Int(Buf:DataBuffer, Offset:Int, Count:Int)
		If (Self._Position + Count > Self._Length) Then
			'Count = Max(Self._Length - Self._Position, 0)
			Count = 0
		Endif
		
		For Local Index:= 0 Until Count
			Self._Buffer.PokeByte(Self._Offset+Self._Position+Index, Buf.PeekByte(Offset+Index))
		Next
		
		Self._Position += Count
		
		Return Count
	End
	
	' Methods (Private):
	Private
	
	' Nothing so far.
	
	Public
	
	' Properties (Public):
	Method Buffer:DataBuffer() Property
		Return Self._Buffer
	End
	
	Method Length:Int() Property
		Return Self._Length
	End
	
	Method Position:Int() Property
		Return Self._Position
	End
	
	Method BytesLeft:Int() Property
		Return Max(_Length - _Position, 0)
	End
	
	Method FixByteOrder:Bool() Property
		Return Self.BigEndianStorage
	End
	
	Method FixByteOrder:Void(Input:Bool) Property
		Self.BigEndianStorage = Input
		
		Return
	End
	
	Method Buffer:Void(Input:DataBuffer) Property
		Self._Buffer = Input
		
		Return
	End
		
	' Properties (Private):
	Private
	
	#Rem
	Method Position:Void(Input:Int) Property
		Self._Position = Input
		
		Return
	End
	#End
	
	Public
	
	' Fields (Public):
	Field ShouldResize:Bool
	Field Path:String
	
	Field _Buffer:DataBuffer
	Field _Length:Int, _Offset:Int
	Field _Position:Int
	
	Field SizeLimit:Int
	
	' Booleans / Flags:
	Field KeepBuffer:Bool
	Field BigEndianStorage:Bool
	
	' Fields (Private):
	Private
	
	' Nothing so far.
	
	Public
End

' Functions (Public):

' Basically just a modified version of the 'util' module's implementation.
Function ResizeBuffer:DataBuffer(Buffer:DataBuffer, Size:Int=0, CopyData:Bool=True, DiscardOldBuffer:Bool=False, OnlyWhenDifferentSizes:Bool=False)
	Local BufferAvailable:Bool = (Buffer <> Null)
	
	If (BufferAvailable And OnlyWhenDifferentSizes) Then
		If (Size <> 0 And Buffer.Length() = Size) Then
			Return Buffer
		Endif
	Endif
	
	If (Size = 0) Then
		Size = Buffer.Length()*2
	Endif
	
	' Allocate a new data-buffer.
	Local B:= New DataBuffer(Size)
	
	' Copy the buffer's bytes over to 'B'.
	If (BufferAvailable) Then
		If (CopyData) Then
			' Copy the contents of 'Buffer' to the newly generated buffer-object.
			Buffer.CopyBytes(0, B, 0, Buffer.Length())
		Endif
		
		If (DiscardOldBuffer) Then
			' Discard the old buffer.
			Buffer.Discard()
		Endif
	Endif
	
	' Return the newly generated buffer.
	Return B
End

' Functions (Private):
Private

' Nothing so far.

Public