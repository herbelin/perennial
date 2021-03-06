(* autogenerated from awol *)
From Perennial.goose_lang Require Import prelude.

(* disk FFI *)
From Perennial.goose_lang Require Import ffi.disk_prelude.

(* 10 is completely arbitrary *)
Definition MaxTxnWrites : expr := #10.

Definition logLength : expr := #1 + #2 * MaxTxnWrites.

Module Log.
  Definition S := struct.decl [
    "l" :: lockRefT;
    "cache" :: mapT disk.blockT;
    "length" :: refT uint64T
  ].
End Log.

Definition intToBlock: val :=
  λ: "a",
    let: "b" := NewSlice byteT disk.BlockSize in
    UInt64Put "b" "a";;
    "b".

Definition blockToInt: val :=
  λ: "v",
    let: "a" := UInt64Get "v" in
    "a".

(* New initializes a fresh log *)
Definition New: val :=
  λ: <>,
    let: "diskSize" := disk.Size #() in
    (if: "diskSize" ≤ logLength
    then
      Panic ("disk is too small to host log");;
      #()
    else #());;
    let: "cache" := NewMap disk.blockT in
    let: "header" := intToBlock #0 in
    disk.Write #0 "header";;
    let: "lengthPtr" := ref (zero_val uint64T) in
    "lengthPtr" <-[refT uint64T] #0;;
    let: "l" := lock.new #() in
    struct.mk Log.S [
      "cache" ::= "cache";
      "length" ::= "lengthPtr";
      "l" ::= "l"
    ].

Definition Log__lock: val :=
  λ: "l",
    lock.acquire (struct.get Log.S "l" "l").

Definition Log__unlock: val :=
  λ: "l",
    lock.release (struct.get Log.S "l" "l").

(* BeginTxn allocates space for a new transaction in the log.

   Returns true if the allocation succeeded. *)
Definition Log__BeginTxn: val :=
  λ: "l",
    Log__lock "l";;
    let: "length" := ![uint64T] (struct.get Log.S "length" "l") in
    (if: ("length" = #0)
    then
      Log__unlock "l";;
      #true
    else
      Log__unlock "l";;
      #false).

(* Read from the logical disk.

   Reads must go through the log to return committed but un-applied writes. *)
Definition Log__Read: val :=
  λ: "l" "a",
    Log__lock "l";;
    let: ("v", "ok") := MapGet (struct.get Log.S "cache" "l") "a" in
    (if: "ok"
    then
      Log__unlock "l";;
      "v"
    else
      Log__unlock "l";;
      let: "dv" := disk.Read (logLength + "a") in
      "dv").

Definition Log__Size: val :=
  λ: "l",
    let: "sz" := disk.Size #() in
    "sz" - logLength.

(* Write to the disk through the log. *)
Definition Log__Write: val :=
  λ: "l" "a" "v",
    Log__lock "l";;
    let: "length" := ![uint64T] (struct.get Log.S "length" "l") in
    (if: "length" ≥ MaxTxnWrites
    then
      Panic ("transaction is at capacity");;
      #()
    else #());;
    let: "aBlock" := intToBlock "a" in
    let: "nextAddr" := #1 + #2 * "length" in
    disk.Write "nextAddr" "aBlock";;
    disk.Write ("nextAddr" + #1) "v";;
    MapInsert (struct.get Log.S "cache" "l") "a" "v";;
    struct.get Log.S "length" "l" <-[refT uint64T] "length" + #1;;
    Log__unlock "l".

(* Commit the current transaction. *)
Definition Log__Commit: val :=
  λ: "l",
    Log__lock "l";;
    let: "length" := ![uint64T] (struct.get Log.S "length" "l") in
    Log__unlock "l";;
    let: "header" := intToBlock "length" in
    disk.Write #0 "header".

Definition getLogEntry: val :=
  λ: "logOffset",
    let: "diskAddr" := #1 + #2 * "logOffset" in
    let: "aBlock" := disk.Read "diskAddr" in
    let: "a" := blockToInt "aBlock" in
    let: "v" := disk.Read ("diskAddr" + #1) in
    ("a", "v").

(* applyLog assumes we are running sequentially *)
Definition applyLog: val :=
  λ: "length",
    let: "i" := ref #0 in
    (for: (#true); (Skip) :=
      (if: ![uint64T] "i" < "length"
      then
        let: ("a", "v") := getLogEntry (![uint64T] "i") in
        disk.Write (logLength + "a") "v";;
        "i" <-[uint64T] ![uint64T] "i" + #1;;
        Continue
      else Break)).

Definition clearLog: val :=
  λ: <>,
    let: "header" := intToBlock #0 in
    disk.Write #0 "header".

(* Apply all the committed transactions.

   Frees all the space in the log. *)
Definition Log__Apply: val :=
  λ: "l",
    Log__lock "l";;
    let: "length" := ![uint64T] (struct.get Log.S "length" "l") in
    applyLog "length";;
    clearLog #();;
    struct.get Log.S "length" "l" <-[refT uint64T] #0;;
    Log__unlock "l".

(* Open recovers the log following a crash or shutdown *)
Definition Open: val :=
  λ: <>,
    let: "header" := disk.Read #0 in
    let: "length" := blockToInt "header" in
    applyLog "length";;
    clearLog #();;
    let: "cache" := NewMap disk.blockT in
    let: "lengthPtr" := ref (zero_val uint64T) in
    "lengthPtr" <-[refT uint64T] #0;;
    let: "l" := lock.new #() in
    struct.mk Log.S [
      "cache" ::= "cache";
      "length" ::= "lengthPtr";
      "l" ::= "l"
    ].
