(* autogenerated from github.com/mit-pdos/goose-nfsd/util *)
From Perennial.goose_lang Require Import prelude.
From Perennial.goose_lang Require Import ffi.disk_prelude.

Definition Debug : expr := #0.

Definition DPrintf: val :=
  rec: "DPrintf" "level" "format" "a" :=
    (if: "level" ≤ Debug
    then
      (* log.Printf(format, a...) *)
      #()
    else #()).

Definition RoundUp: val :=
  rec: "RoundUp" "n" "sz" :=
    ("n" + "sz" - #1) `quot` "sz".

Definition Min: val :=
  rec: "Min" "n" "m" :=
    (if: "n" < "m"
    then "n"
    else "m").

(* returns n+m>=2^64 (if it were computed at infinite precision) *)
Definition SumOverflows: val :=
  rec: "SumOverflows" "n" "m" :=
    "n" + "m" < "n".

Definition SumOverflows32: val :=
  rec: "SumOverflows32" "n" "m" :=
    "n" + "m" < "n".
