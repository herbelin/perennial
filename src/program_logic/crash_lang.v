From iris.program_logic Require Export language.
Set Default Proof Using "Type".

Structure crash_semantics (Λ: language) :=
  CrashSemantics {
      crash_prim_step : state Λ → state Λ → Prop;
  }.

Arguments crash_prim_step {_}.

Section crash_language.
  Context {Λ: language}.
  Context {CS: crash_semantics Λ}.

  Inductive status : Set :=
  | Crashed
  | Normal.

  (* Execution with crashes and a fresh procedure to run. list nat argument counts
     steps in-between each crash. The mneominic is now that "r" stands for "resume" *)
  Inductive nrsteps (r: expr Λ) : list nat → cfg Λ → list (observation Λ) → cfg Λ → status → Prop :=
  | nrsteps_normal n ρ1 ρ2 κs:
      nsteps n ρ1 κs ρ2 →
      nrsteps r [n] ρ1 κs ρ2 Normal
  | nrsteps_crash n1 ns ρ1 ρ2 ρ3 σ κs1 κs2 s:
      nsteps n1 ρ1 κs1 ρ2 →
      crash_prim_step CS (ρ2.2) σ →
      nrsteps r ns ([r], σ) κs2 ρ3 s →
      nrsteps r (n1 :: ns) ρ1 (κs1 ++ κs2) ρ3 Crashed.

  Inductive erased_rsteps (r: expr Λ) : cfg Λ → cfg Λ → status → Prop :=
  | erased_rsteps_normal ρ1 ρ2:
      rtc erased_step ρ1 ρ2 →
      erased_rsteps r ρ1 ρ2 Normal
  | erased_rsteps_crash ρ1 ρ2 ρ3 σ s:
      rtc erased_step ρ1 ρ2 →
      crash_prim_step CS (ρ2.2) σ →
      erased_rsteps r ([r], σ) ρ3 s →
      erased_rsteps r ρ1 ρ3 Crashed.

  Inductive erased_steps_list: cfg Λ → cfg Λ → list (state Λ) → Prop :=
  | eslist_refl ρ σ:
      ρ.2 = σ →
      erased_steps_list ρ ρ [σ]
  | eslist_r ρ1 ρ2 ρ3 σs σ:
      erased_steps_list ρ1 ρ2 σs →
      erased_step ρ2 ρ3 →
      ρ3.2 = σ →
      erased_steps_list ρ1 ρ3 (σs ++ [σ]).

  Inductive erased_rsteps_list (r: expr Λ): cfg Λ → cfg Λ → list (cfg Λ * list (state Λ)) → Prop :=
  | erslist_normal ρ1 ρ2 σs:
      erased_steps_list ρ1 ρ2 σs →
      erased_rsteps_list r ρ1 ρ2 [(ρ2, σs)]
  | erslist_r ρ1 ρ2 ρ3 σss σcrash σs:
      erased_rsteps_list r ρ1 ρ2 σss →
      crash_prim_step CS (ρ2.2) σcrash →
      erased_steps_list ([r], σcrash) ρ3 σs →
      erased_rsteps_list r ρ1 ρ3 (σss ++ [(ρ3, σs)]).

  Lemma eslist_l ρ1 ρ2 ρ3 σs σ:
    erased_step ρ1 ρ2 →
    erased_steps_list ρ2 ρ3 σs →
    ρ1.2 = σ →
    erased_steps_list ρ1 ρ3 (σ :: σs).
  Proof.
    intros Hstep Hsteps. revert ρ1 Hstep. induction Hsteps.
    - intros. replace (σ :: _) with ([σ] ++ [σ0]) by eauto. econstructor; eauto.
      econstructor; auto.
    - intros. rewrite app_comm_cons. econstructor; eauto.
  Qed.

  Definition never_stuck (e1 r1: expr Λ) (σ1: state Λ) :=
    (∀ e2 σ2 t2 stat, erased_rsteps r1 ([e1], σ1) (t2, σ2) stat →
      e2 ∈ t2 → (is_Some (to_val e2) ∨ reducible e2 σ2)).

  Lemma nrsteps_normal_empty_prefix r ns n ρ1 κ ρ2:
    nrsteps r (ns ++ [n]) ρ1 κ ρ2 Normal →
    ns = [].
  Proof.
    destruct ns as [| ? ns]; first eauto.
    inversion 1. subst.
    destruct ns; simpl in *; congruence.
  Qed.

  Lemma nrsteps_snoc r ns ρ1 κ ρ2 s:
    nrsteps r (ns) ρ1 κ ρ2 s →
    ∃ ns' n, ns = ns' ++ [n].
  Proof.
    destruct ns using rev_ind.
    - inversion 1.
    - eauto.
  Qed.

  Lemma erased_rsteps_nrsteps r ρ1 ρ2 s :
    erased_rsteps r ρ1 ρ2 s ↔ ∃ n κs, nrsteps r n ρ1 κs ρ2 s.
  Proof.
    split.
    - induction 1 as [?? H| ????? H Hcrash ? IH].
      * eapply erased_steps_nsteps in H as (n&κs&H).
        exists [n], κs. econstructor; eauto.
      * destruct IH as (ns&κs2&IH).
        eapply erased_steps_nsteps in H as (n1&κs1&H).
        exists (n1 :: ns), (κs1 ++ κs2).
        econstructor; eauto.
    - intros (n&κs&Hsteps).
      induction Hsteps; econstructor; eauto; eapply erased_steps_nsteps; eauto.
  Qed.

End crash_language.