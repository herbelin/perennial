From Goose.github_com.mit_pdos.goose_nfsd Require Import wal.
From Perennial.program_proof Require Import proof_prelude.
From Perennial.program_proof Require Import wal.abstraction.
From Perennial.program_proof Require Import wal.circular_proof.

Definition LogPositionT := wal.LogPosition.
Definition LogPosition := u64.

Class ToVal {ext:ext_op} {ext_ty: ext_types ext} T (t: @ty val_tys) :=
  { to_val : T → val;
    to_val_ty : forall x, val_ty (to_val x) t;
  }.

Transparent slice.T.

Module WalogM.
  Record t :=
    mk { memLock: loc;
         d: Disk_ty;
         circ: loc;

         (* these are condition variables and behave like indirect access to
         memLock *)
         condLogger: loc;
         condInstall: loc;

         memLog: Slice.t; (* size 2 *)
         memStart: LogPosition;
         nextDiskEnd: LogPosition;

         (* these have no bearing on the abstraction relation *)
         shutdown: bool;
         nthread: u64;
         condShut: loc;

         memLogMap: loc;
       }.

  Instance t_val : ToVal t (struct.t Walog.S).
  refine {| to_val x :=
              (#x.(memLock), ExtV DiskInterfaceVal, #x.(circ),
               #x.(condLogger), #x.(condInstall),
               slice_val x.(memLog), #(LitInt x.(memStart)), #(LitInt x.(nextDiskEnd)),
               #x.(shutdown), #x.(nthread), #x.(condShut),
               #x.(memLogMap))%V |}.
  intros []; simpl.
  repeat constructor; simpl.
  { rewrite /Disk.
    exact (ext_def_ty DiskInterfaceTy). }
  Defined.
End WalogM.

Section heap.
Context `{!heapG Σ}.
Context `{!lockG Σ}.
Implicit Types (v:val) (z:Z).

Definition walN: namespace := nroot .@ "wal".

Definition lockInv (l: loc) (σ: log_state.t): iProp Σ :=
  (∃ memLog diskLog
     (memStart: u64) (diskStart: u64) (nextDiskEnd: u64)
     memLogCache,
      (is_circular (l +ₗ 2) (circΣ.mk diskLog diskStart)) ∗
      (∃ s, (l +ₗ 5) ↦[slice.T (struct.t Update.S)] (slice_val s) ∗
      updates_slice s memLog) ∗
      (l +ₗ 7) ↦[uint64T] #memStart ∗
      (l +ₗ 8) ↦[uint64T] #nextDiskEnd ∗
      is_map (l +ₗ 12) memLogCache ∗
      ⌜int.val memStart ≤ int.val diskStart⌝ ∗
      ⌜∃ memLog', memLog = diskLog ++ memLog'⌝
  ).

Definition is_wal (l: loc) (σ: log_state.t): iProp Σ :=
  ∃ γ, is_lock walN γ #(l +ₗ 0) (lockInv l σ) ∗
       lock.is_cond walN γ (l +ₗ 4) (lockInv l σ) ∗
       lock.is_cond walN γ (l +ₗ 5) (lockInv l σ).

End heap.