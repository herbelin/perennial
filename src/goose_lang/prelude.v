From Perennial.goose_lang Require Export
     lang notation slice map struct typing encoding locks.

(* We provide stubs here for primitive operations to make the Goose unit tests
   compile. *)

(* TODO: replace all of these stubs with real operations *)

Definition uint64_to_string {ext: ext_op}: val := λ: <>, #().
Definition strLen {ext: ext_op}: val := λ: "s", #0.

Module Data.
  Section goose_lang.
    Context `{ext_ty:ext_types}.
    Axiom stringToBytes: val.
    Axiom bytesToString: val.
    Axiom stringToBytes_t : ⊢ stringToBytes : (stringT -> slice.T byteT).
    Axiom bytesToString_t : ⊢ bytesToString : (slice.T byteT -> stringT).
    Definition randomUint64: val := λ: <>, #0.
    Theorem randomUint64_t: ⊢ randomUint64 : (unitT -> uint64T).
    Proof.
      typecheck.
    Qed.
  End goose_lang.
End Data.

Hint Resolve Data.stringToBytes_t Data.bytesToString_t : types.

Opaque Data.randomUint64.
Hint Resolve Data.randomUint64_t : types.

Module FS.
  Section goose_lang.
    Context {ext:ext_op}.
    Definition open: val := λ: <>, #().
    Definition close: val := λ: <>, #().
    Definition list: val := λ: <>, #().
    Definition size: val := λ: <>, #().
    Definition readAt: val := λ: <>, #().
    Definition create: val := λ: <>, #().
    Definition append: val := λ: <>, #().
    Definition delete: val := λ: <>, #().
    Definition rename: val := λ: <>, #().
    Definition truncate: val := λ: <>, #().
    Definition atomicCreate: val := λ: <>, #().
    Definition link: val := λ: <>, #().
  End goose_lang.
End FS.
Definition fileT {val_tys: val_types}: ty := unitT.

Module Globals.
  Section goose_lang.
    Context {ext:ext_op}.
    Definition getX: val := λ: <>, #().
    Definition setX: val := λ: <>, #().
  End goose_lang.
End Globals.
