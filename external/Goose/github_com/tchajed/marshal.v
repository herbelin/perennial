(* autogenerated from marshal *)
From Perennial.goose_lang Require Import prelude.

(* disk FFI *)
From Perennial.goose_lang Require Import ffi.disk_prelude.

(* Enc is a stateful encoder for a statically-allocated array. *)
Module Enc.
  Definition S := struct.decl [
    "b" :: slice.T byteT;
    "off" :: refT uint64T
  ].
End Enc.

Definition NewEnc: val :=
  λ: "sz",
    struct.mk Enc.S [
      "b" ::= NewSlice byteT "sz";
      "off" ::= ref (zero_val uint64T)
    ].

Definition Enc__PutInt: val :=
  λ: "enc" "x",
    let: "off" := ![uint64T] (struct.get Enc.S "off" "enc") in
    UInt64Put (SliceSkip byteT (struct.get Enc.S "b" "enc") "off") "x";;
    struct.get Enc.S "off" "enc" <-[refT uint64T] ![uint64T] (struct.get Enc.S "off" "enc") + #8.

Definition Enc__PutInt32: val :=
  λ: "enc" "x",
    let: "off" := ![uint64T] (struct.get Enc.S "off" "enc") in
    UInt32Put (SliceSkip byteT (struct.get Enc.S "b" "enc") "off") "x";;
    struct.get Enc.S "off" "enc" <-[refT uint64T] ![uint64T] (struct.get Enc.S "off" "enc") + #4.

Definition Enc__PutInts: val :=
  λ: "enc" "xs",
    ForSlice uint64T <> "x" "xs"
      (Enc__PutInt "enc" "x").

Definition Enc__PutBytes: val :=
  λ: "enc" "b",
    let: "off" := ![uint64T] (struct.get Enc.S "off" "enc") in
    let: "n" := SliceCopy byteT (SliceSkip byteT (struct.get Enc.S "b" "enc") "off") "b" in
    struct.get Enc.S "off" "enc" <-[refT uint64T] ![uint64T] (struct.get Enc.S "off" "enc") + "n".

Definition Enc__Finish: val :=
  λ: "enc",
    struct.get Enc.S "b" "enc".

(* Dec is a stateful decoder that returns values encoded
   sequentially in a single slice. *)
Module Dec.
  Definition S := struct.decl [
    "b" :: slice.T byteT;
    "off" :: refT uint64T
  ].
End Dec.

Definition NewDec: val :=
  λ: "b",
    struct.mk Dec.S [
      "b" ::= "b";
      "off" ::= ref (zero_val uint64T)
    ].

Definition Dec__GetInt: val :=
  λ: "dec",
    let: "off" := ![uint64T] (struct.get Dec.S "off" "dec") in
    struct.get Dec.S "off" "dec" <-[refT uint64T] ![uint64T] (struct.get Dec.S "off" "dec") + #8;;
    UInt64Get (SliceSkip byteT (struct.get Dec.S "b" "dec") "off").

Definition Dec__GetInt32: val :=
  λ: "dec",
    let: "off" := ![uint64T] (struct.get Dec.S "off" "dec") in
    struct.get Dec.S "off" "dec" <-[refT uint64T] ![uint64T] (struct.get Dec.S "off" "dec") + #4;;
    UInt32Get (SliceSkip byteT (struct.get Dec.S "b" "dec") "off").

Definition Dec__GetInts: val :=
  λ: "dec" "num",
    let: "xs" := ref (zero_val (slice.T uint64T)) in
    let: "i" := ref #0 in
    (for: (λ: <>, ![uint64T] "i" < "num"); (λ: <>, "i" <-[uint64T] ![uint64T] "i" + #1) := λ: <>,
      "xs" <-[slice.T uint64T] SliceAppend uint64T (![slice.T uint64T] "xs") (Dec__GetInt "dec");;
      Continue);;
    ![slice.T uint64T] "xs".

Definition Dec__GetBytes: val :=
  λ: "dec" "num",
    let: "off" := ![uint64T] (struct.get Dec.S "off" "dec") in
    let: "b" := SliceSubslice byteT (struct.get Dec.S "b" "dec") "off" ("off" + "num") in
    struct.get Dec.S "off" "dec" <-[refT uint64T] ![uint64T] (struct.get Dec.S "off" "dec") + "num";;
    "b".
