From iris.proofmode Require Import coq_tactics reduction.
From Perennial.goose_lang Require Import basic_triples.
From Perennial.goose_lang Require Import map.
Import uPred.

Section heap.
Context `{ffi_sem: ext_semantics} `{!ffi_interp ffi} `{!heapG Σ}.
Context {ext_ty: ext_types ext}.
Implicit Types P Q : iProp Σ.
Implicit Types Φ : val → iProp Σ.
Implicit Types Δ : envs (uPredI (iResUR Σ)).
Implicit Types v : val.
Implicit Types vs : list val.
Implicit Types z : Z.
Implicit Types t : ty.
Implicit Types stk : stuckness.
Implicit Types off : nat.

(* The model of a map is [gmap u64 val * val] (the second value is the default).

The abstraction relation (actually abstraction function) between a val mv and a
model m is m = map_val mv.

The models are canonical due to extensionality of gmaps, but the concrete
representation tracks all insertions (including duplicates). *)

Fixpoint map_val (v: val) : option (gmap u64 val * val) :=
  match v with
  | MapConsV k v m =>
    match map_val m with
    | Some (m, def) => Some (<[ k := v ]> m, def)
    | None => None
    end
  | MapNilV def => Some (∅, def)
  | _ => None
  end.

Definition val_of_map (m_def: gmap u64 val * val) : val :=
  let (m, def) := m_def in
  fold_right (λ '(k, v) mv, MapConsV k v mv)
             (MapNilV def)
             (map_to_list m).

Theorem map_val_id : forall v m_def,
    map_val v = Some m_def ->
    val_of_map m_def = v.
Proof.
  induction v; intros [m def]; try solve [ inversion 1 ]; simpl; intros H.
  - inversion H; subst; clear H.
    rewrite map_to_list_empty; simpl; auto.
  - destruct v; try congruence.
    destruct v1; try congruence.
    destruct v1_1; try congruence.
    destruct l; try congruence.
    destruct_with_eqn (map_val v2); try congruence.
    specialize (IHv p).
    destruct p as [m' def'].
    inversion H; subst; clear H.
    (* oops, the normal val induction principle is too weak to prove this *)
Abort.

Definition map_get (m_def: gmap u64 val * val) (k: u64) : (val*bool) :=
  let (m, def) := m_def in
  let r := default def (m !! k) in
  let ok := bool_decide (is_Some (m !! k)) in
  (r, ok).

Definition map_insert (m_def: gmap u64 val * val) (k: u64) (v: val) : gmap u64 val * val :=
  let (m, def) := m_def in
  (<[ k := v ]> m, def).

Definition map_del (m_def: gmap u64 val * val) (k: u64) : gmap u64 val * val :=
  let (m, def) := m_def in
  (delete k m, def).


Lemma map_get_empty def k : map_get (∅, def) k = (def, false).
Proof.
  reflexivity.
Qed.

Lemma map_get_insert k v m def :
  map_get (<[k:=v]> m, def) k = (v, true).
Proof.
  rewrite /map_get.
  rewrite lookup_insert //.
Qed.

Lemma map_get_insert_ne k k' v m def :
  k ≠ k' ->
  map_get (<[k:=v]> m, def) k' = map_get (m, def) k'.
Proof.
  intros Hne.
  rewrite /map_get.
  rewrite lookup_insert_ne //.
Qed.

Lemma map_val_split mv m :
  map_val mv = Some m ->
  {∃ def, mv = MapNilV def ∧ m = (∅, def)} +
  {∃ k v mv' m', mv = MapConsV k v mv' ∧ map_val mv' = Some m' ∧ m = (<[k:=v]> (fst m'), snd m')}.
Proof.
  intros H.
  destruct mv; inversion H; subst; [ left | right ].
  - exists mv; auto.
  - destruct mv; try solve [ inversion H1 ].
    destruct mv1; try solve [ inversion H1 ].
    destruct mv1_1; try solve [ inversion H1 ].
    destruct l; try solve [ inversion H1 ].
    destruct_with_eqn (map_val mv2); try solve [ inversion H1 ].
    destruct p; inversion H1; subst; clear H1.
    eexists _, _, _, _; intuition eauto.
Qed.

Definition wp_NewMap stk E T :
  {{{ True }}}
    NewMap T @ stk; E
  {{{ mref mv def, RET #mref;
    mref ↦ Free mv ∗ ⌜map_val mv = Some (∅, def)⌝ }}}.
Proof.
  iIntros (Φ) "_ HΦ".
  wp_apply (wp_alloc _ _ (mapValT T)).
  {
    (* This seems messy; is there a cleaner way? Why [zero_val_ty']? *)
    econstructor. apply zero_val_ty'.
  }
  iIntros (mref) "Hm".
  iApply "HΦ".

  (* This seems messy.. *)
  rewrite /struct_mapsto /= loc_add_0.
  iDestruct "Hm" as "[[Hm _] %]".
  iFrame.
  auto.
Qed.

Definition wp_MapGet stk E mref (m: gmap u64 val * val) mv k :
  {{{ mref ↦ Free mv ∗ ⌜map_val mv = Some m⌝ }}}
    MapGet #mref #k @ stk; E
  {{{ v ok, RET (v, #ok); ⌜map_get m k = (v, ok)⌝ ∗
                          mref ↦ Free mv }}}.
Proof.
  iIntros (𝛷) "[Hmref %] H𝛷".
  wp_call.
  wp_load.
  wp_pure (_ _).
  iAssert (∀ v ok, ⌜map_get m k = (v, ok)⌝ -∗ 𝛷 (v, #ok)%V)%I with "[Hmref H𝛷]" as "H𝛷".
  { iIntros (v ok) "%".
    by iApply ("H𝛷" with "[$Hmref]"). }
  iLöb as "IH" forall (m mv H).
  wp_call.
  destruct (map_val_split _ _ H).
  - (* nil *)
    destruct e as [def ?]; intuition subst.
    wp_pures.
    iApply "H𝛷".
    rewrite map_get_empty; auto.
  - destruct e as [k' [v [mv' [m' ?]]]]; intuition subst.
    wp_pures.
    wp_if_destruct.
    + wp_pures.
      iApply "H𝛷".
      rewrite map_get_insert //.
    + iApply "IH".
      * eauto.
      * iIntros (v' ok) "%".
        iApply "H𝛷".
        rewrite map_get_insert_ne //; try congruence.
        destruct m'; eauto.
Qed.

Definition wp_MapInsert stk E mref (m: gmap u64 val * val) mv k v' :
  {{{ mref ↦ Free mv ∗ ⌜map_val mv = Some m⌝ }}}
    MapInsert #mref #k v' @ stk; E
  {{{ mv', RET #(); mref ↦ Free mv' ∗
                    ⌜map_val mv' = Some (map_insert m k v')⌝ }}}.
Proof.
  iIntros (𝛷) "[Hmref %] H𝛷".
  wp_call.
  wp_load.
  wp_store.
  iApply ("H𝛷" with "[$Hmref]").
  iPureIntro.
  simpl.
  rewrite H.
  destruct m; simpl; auto.
Qed.

Definition wp_MapDelete stk E mref (m: gmap u64 val * val) mv k :
  {{{ mref ↦ Free mv ∗ ⌜map_val mv = Some m⌝ }}}
    MapDelete #mref #k @ stk; E
  {{{ mv', RET #(); mref ↦ Free mv' ∗
                    ⌜map_val mv' = Some (map_del m k)⌝ }}}.
Proof.
  iIntros (𝛷) "[Hmref %] H𝛷".
Abort.

(* TODO: specify MapIter *)

End heap.
