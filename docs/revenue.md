# `sirus revenue` and `sirus reconcile`

The scanner prices money at risk in **code**. This prices it in **operations** —
failed payments, abandoned checkouts, receivables going stale, and three sets of
books that disagree. Same product, same vocabulary, same refusal to print a
number nobody computed.

Three loops, each closing end to end with no backend:

| Loop | Command | What it answers |
|---|---|---|
| Detect + measure | `sirus revenue detect \| eval` | which records are worth working, and how well the detector actually does on data it never saw |
| Decide + recover | `sirus revenue recover` | what to do about each one, what that recovered, and where it had to stop |
| Reconcile | `sirus reconcile` | which captures, settlements and bank lines are the same money, and what is left unexplained |

```bash
sirus revenue gen batch          # a reproducible batch from a seed
sirus revenue detect batch       # score it, diagnose it, price it
sirus revenue eval batch         # measure it on the held-out half
sirus revenue recover batch      # run the bounded workflow, write a signed trail
sirus revenue audit --verify batch/recovery-<id>.json

sirus reconcile books --gen      # three sets of books that disagree
sirus reconcile books            # match them, and list what did not match
```

---

## 1. Detection, and metrics that cannot flatter themselves

**The target is uplift, not recovery.** `recoverable AND NOT self_heals`. A
payment the customer would have retried tomorrow is not revenue anybody
recovered — and a model trained on recovery learns to chase exactly those,
because they are the easiest positives in the data.

**Labels live in a different file from the records.** `records.jsonl` is what
the detector reads; `truth.jsonl` is what it is scored against. Leakage is
structurally impossible rather than a matter of discipline.

**The split is a hash of the id**, not a random draw and not a time cut: the
same on every machine, and the injected incidents land on both sides.

**How far to trust a score is part of the score.** The mean gap between
confidence and outcome runs about **15% on a 185-record batch and about 5% at
ten times that** — measured across seeds, not guessed. Below 250 held-out
records the evaluation says so and tells you to read the scores as a ranking
rather than as probabilities, and `explain` repeats it beside the shrink. A bin
with fewer than 20 records gets no verdict at all: the top of a scorecard is
always sparse, and one record that happened to come back reads as "said 88%, was
100%", which is noise wearing a finding's clothes.

**The model is L2-regularised logistic regression**, fitted by AdaGrad on the
training half, with the penalty chosen by four-fold cross-validation *inside*
that half. Every step still prints as a sentence somebody can disagree with —
a coefficient is a contribution to the log-odds, so `exp(coefficient)` reads
exactly as the old likelihood ratio did: `failure=psp_degraded ×4.2`.

It was naive Bayes on odds, and the reason it changed is worth stating. Naive
Bayes multiplies one likelihood ratio per feature as though the features were
independent, and `rail` and `failure_code` plainly are not — a NACH mandate
fails for different reasons than a card. That counted one fact twice. Naming the
interactions explicitly made it worse rather than better, because naive Bayes
then counted `failure`, `rail`, *and* the pair. Logistic regression learns one
joint set of coefficients, so a correlated pair shares the weight.

**Calibration is kept only when it helps.** Naive Bayes is reliably
overconfident and a two-parameter Platt shrink was a clear win over it. A
regularised logistic fit arrives close to calibrated, and squeezing a second
sigmoid onto it made held-out calibration error *worse* — 8.9% against 6.6%. The
fit is now scored against the identity on rows it was not fitted to, and the
identity wins when Platt has not earned its place. A calibration step that
decalibrates is worth nothing, and shipping one because it is called calibration
is how a report earns the word without the property.

**Records are chosen by expected value under a capacity cap**, not by score.
Ranking by probability alone lost to sorting by amount in a spreadsheet, which
is what a model that never multiplies probability by money deserves. Capacity is
the real constraint — card networks watch decline-and-retry ratios, NACH caps
re-presentments, TRAI caps contact, and analysts are finite.

### The honest result

On money, across eight seeds, expected-value ranking beats sorting by amount by
**+1.0% at 20% capacity and +4.0% at 5%**, winning on seven seeds of eight. When
amounts span a hundredfold and probabilities span threefold, size is already
most of the answer — and the edge is small. It is largest when capacity is
tight, but not monotonically: at 3% it falls back to +2.2%, because with ten
slots the highest expected value and the largest amount are mostly the same
records.

**The edge is a function of capacity, so it is reported as one:**

| capacity | edge over the best runnable heuristic | share of the ceiling |
|---|---|---|
| 3% | +2.2% | 72% |
| 5% | +4.0% | 78% |
| 10% | +0.7% | 83% |
| 20% | +1.0% | 87% |
| 40% | +0.6% | 92% |

A single number invites "so your model is worth one percent". At the capacity it
happened to be measured at, yes. `sirus revenue eval` prints this curve, and on
any *one* batch several of these points are frequently zero — at tight capacity
the highest expected value and the largest amount are often the same records.
That is why the table above is eight seeds and not one.

**What replacing naive Bayes actually bought, and what it cost.** Both are
measured, and the losses are not omitted. This table is a record of that change,
taken on the seeds as they were named before the rename to `sirus-*`
(D-058), which moved every figure above, and naive Bayes is no longer in the
tree to measure again:

| | naive Bayes | logistic |
|---|---|---|
| edge, 8 seeds | +1.1% | **+1.5%** |
| edge at 3% capacity | +20.4% | **+22.9%** |
| edge at 5% capacity | +7.7% | **+10.2%** |
| edge at 10% capacity | **+3.2%** | +2.1% |
| calibration error, 8 seeds | 7.7% | **6.2%** |
| precision, 8 seeds | **47.2%** | 47.0% |
| precision, headline batch | **46.3%** | 41.8% |
| net, headline batch | **₹7,67,417** | ₹7,50,992 |

It is better at four capacities of five and better calibrated, and it is worse
at 10% capacity and worse on the single headline batch — ₹16,425 of net and four
points of precision. By this surface's own rule that one batch is an anecdote
and the sweep is the measurement (D-026), that is a net win; the anecdote going
the other way is printed here rather than dropped.

Where the policies differ most is not money at all — it is **what gets
touched**:

```
   POLICY                    NET  OUT OF BOUNDS  ACTED ON
   chase everything   INFEASIBLE  ✗ 18           —
      5.0× the 67 interventions available — no model at all — and far past
      what any gateway or contact rule allows
      ₹15,89,129 is what it would net if those limits did not exist
   chase nothing              ₹0  ✓ none         0
      what the money does when left alone
   biggest first      ₹13,35,227  ✗ 1            67
      the spreadsheet heuristic: sort by amount, work down the list
   newest first       ₹10,68,273  ✗ 3            67
      the queue heuristic: work the freshest failures
→  this detector      ₹13,14,917  ✓ none         67
      86% of what was reachable · ₹20.3K behind the best heuristic
   perfect foresight  ₹15,20,829  ✓ none         67
      the ceiling — the best possible choice of the same number of records
```

`chase everything` nets more than the detector and more than the ceiling, and
for a while it sat in the money column as the largest figure in the table with
a note saying it was over capacity. Nothing in that note survives the seconds a
reader spends deciding who won. Capacity is a feasibility test, not a
preference: you cannot perform more interventions than you have room for, and a
policy that cannot be run is not a competitor. Its rupees are still printed,
one line down, as the counterfactual they are.

Forbidden touches are deliberately *not* part of that test. Contacting a
disputed record is a compliance failure, not an impossibility — folding the two
together would let us disqualify `biggest first`, which beats us on the headline
batch, over a single touch. That is the same trick with the sign reversed.

Out of bounds means an open dispute, an issuer risk block, or a shared-signal
cluster. Perfect foresight is not bound by that rule, because it optimises money
alone — on this batch it happens to touch nothing, and on others it does. It is
an upper bound, not a policy anyone may run.

That column exists because the evaluation caught the agent itself retrying a
`risk_block`. The issuer had already refused it, and **a low probability is not
a prohibition**.

### Asking why

```
sirus revenue explain pay_00054 --split test
```

  pay_00054   ₹68,199   nach_mandate insufficient_funds · attempt 1 · kaveri-pg
  scored against split=test — capacity and ranking are relative to the records
  it competed with

  HOW THE SCORE WAS REACHED
    start                 base rate 21.1% — how often acting pays off at all
    dispute                 +7.0  false ×1.62
    attempts                +6.8  1 ×1.60
    amount                  +4.8  50k+ ×1.40
    tenure                  +2.0  long ×1.15
    failure×rail            +1.8  insufficient_funds|nach_mandate ×1.13
    ring                    +1.4  false ×1.10
    kind                    +1.3  payment ×1.10
    history                 −1.0  some ×0.93
    rail                    +0.9  nach_mandate ×1.07
    tenure×history          +0.9  long|some ×1.07
    failure×attempts        +0.8  insufficient_funds|1 ×1.06
    failure                 +0.6  insufficient_funds ×1.04
    degraded                −0.6  false ×0.96
    failure×degraded        +0.6  insufficient_funds|false ×1.04
    shrink                ×1.3283 — fitted on 713 training records, because the model is overconfident
    score                     70  the chance this comes back BECAUSE the agent …

  WHAT THAT IS WORTH
    0.70 × ₹68,199 × 1 (recovery share for payment:insufficient_funds)
      = ₹48,056 expected, against ₹3 to act

  WHAT THE AGENT DOES
    ◆ retry_after_cooldown
    inside this run's capacity of 67 (20% of the batch — a stand-in for one
    cycle of operational headroom)
    ✓ retry_after_cooldown is permitted right now

  WHAT ACTUALLY HAPPENS   from the labels — not used to score
    recoverable, and only if somebody acts
    ₹68,199 of it, and the action that works is retry_after_cooldown
```
  pay_00051   ₹29,733   upi_collect network_timeout · attempt 2 · tatva

  HOW THE SCORE WAS REACHED
    start                 base rate 36.6% — how often acting pays off at all
    failure                 +4.1  network_timeout ×1.33
    rail                    +3.8  upi_collect ×1.30
    attempts                +0.9  2 ×1.06
    shrink                ×0.8556 — the model is overconfident and was told so on the training half
    score                     51  the chance this comes back BECAUSE the agent acts

  WHAT THAT IS WORTH
    0.51 × ₹29,733 × 1 (recovery share for payment:network_timeout)
      = ₹15,276 expected, against ₹3.00 to act

  WHAT THE AGENT DOES
    ◆ retry_now
    ⏸ cooldown — 3.2h since the last attempt, 6h required
        wait 6h before retrying — 30h when the account was empty
        card-scheme retry guidance; a retry into the same empty account is a second decline
```

This is the reason the model is a scorecard rather than something with better
numbers: every line is a sentence a payments lead can disagree with. A model
that cannot be argued with in a meeting does not get used in one.

On a batch with labels it also prints **what actually happens**, last and under
its own heading — including the uncomfortable case where the model scored a
record 88 and the answer key says it was never recoverable by anyone. It plays
no part in the score, and the layout says so by position.

---

### When the world stops matching the training data

```bash
sirus revenue stress
```

The honest objection to every number above is that the model was fitted to the
same generator that produced its test set, so of course it works. A held-out
split answers the weak form of that — same distribution, rows the fit never saw
— and says nothing about the form that actually happens to a deployed detector:
the traffic mix moves, a different gateway degrades, the book shifts toward
mandates, and the weights are still last quarter's.

So the shift is applied to the **generator**, not the sample. A model fitted on
the world as it was meets a world that genuinely obeys different rules, measured
against the same capacity-matched heuristics — which are not trained on anything
and therefore cannot go stale. Six scenarios, written down before they were run:

| world | before | after | retrained | out of bounds |
|---|---|---|---|---|
| no gateway outage at all | −2.2% | **−2.7%** | −2.9% | none |
| book shifts to NACH mandates | −2.2% | **+2.9%** | +3.6% | none |
| card share triples | −2.2% | **−2.5%** | +1.5% | none |
| tickets four times larger | −2.2% | **+4.6%** | +5.5% | none |
| failures recover 25% less often | −2.2% | **+6.5%** | +0.0% | none |
| issuers tighten, risk blocks triple | −2.2% | **−5.9%** | −4.0% | none |

`after` against `before` is what the shift cost. `after` against `retrained` is
how much a refit would recover, which is the only number that says whether to
retrain or to redesign.

**The money edge held in three worlds of six** — and it did not hold in the
unshifted world either. On these four seeds at 5% capacity the detector starts
2.2% *behind* sorting by amount, so `before` is a loss, not a margin to defend.
It is not a robust edge: a risk-block wave costs it most, and retraining wins
back less than two points. That is printed in the same table and the same weight
as the wins, because a robustness report listing only survivals is a marketing
document.

**It touched nothing out of bounds in any of them.** That is the result worth
the section. The money edge is a preference; not contacting a disputed record,
not retrying an issuer's risk block, not working a shared-signal cluster is a
rule — and a rule that only holds on the distribution you trained on is not a
rule. Under six shifts it never broke once.

Two of the scenarios are worth reading twice. Removing the gateway outage makes
the detector *worse*, because degradation is the signal it leans on hardest, and
with it gone there is little left to rank on but size — which the heuristic
already does. And where `retrained` is worse than `after` — harder recovery,
where a refit gives back all 6.5 points — refitting made things worse: a model
with nothing to say about a portfolio it was not designed for cannot be trained
into having something to say.

---

## 2. Recovery: bounded, escalating, and auditable

Choosing the intervention is a lookup, not a model. What to do about an expired
card is not a statistical question: the card is expired. The model decided
*whether* the record was worth the capacity; the remedy is domain knowledge and
belongs where a payments person can read it line by line.

### The stopping rules

Each carries what it stops and the obligation behind it. They are **configured
policy, not legal advice** — frameworks are named so a compliance team knows
which of their own rules to check the numbers against.

| Rule | Stops | Basis |
|---|---|---|
| `dispute_hold` | any contact or retry while a dispute is open | card-scheme dispute handling |
| `risk_hold` | retrying what the issuer refused on risk grounds | a retry is a second attempt at a refusal |
| `ring_hold` | automated action on shared-signal clusters | internal — goes to a human, never a retry |
| `mandate_revoked` | re-presenting a revoked mandate | NPCI e-mandate/NACH — that is an unauthorised debit |
| `mandate_cap` | a fourth re-presentment | NPCI NACH re-presentment limits |
| `retry_cap` | a fifth attempt across all rails | scheme retry limits, gateway decline ratios |
| `cooldown` | retrying too soon — longer when the account was empty | a retry into an empty account is a second decline |
| `quiet_hours` | SMS/WhatsApp/voice 21:00–09:00 **local** | TRAI commercial-communication timing |
| `dnd` | non-email push to a party on DND | TRAI DND registry |
| `consent` | contact on a channel with no consent | DPDP 2023 §6 |
| `contact_frequency` | a third message in a day | internal — the line between collection and harassment is a number |
| `budget` | spending past the cap | internal — a bounded agent has a stated worst case |
| `circuit_breaker` | the whole run, when recovery falls far below expectation | internal — a model that stopped working should stop acting |

Cooldowns and quiet hours are a *not yet* rather than a *no*: the run reschedules
to the first permitted moment, so it comes back at 09:00 rather than abandoning
the record. Deferrals are capped, which is what guarantees termination.

### They are your numbers

Every threshold above is set in `sirus.yaml`, and `sirus init` scaffolds the
block commented out. Pin only what you argue about; the rest falls back to a
documented default.

```yaml
revenue:
  capacity: 200
  budget_inr: 50000
  contacts_per_day: 2
  quiet_hours: { from: 21, to: 9 }
  timezone: Asia/Kolkata        # the zone quiet hours are read in, never the server's
  mandate_attempts: 3
  costs:
    annoyance_inr: 12           # the charge for chasing someone who'd have paid anyway
```

Two things follow from this that are easy to get wrong. A run under a project's
own policy **says so** in its banner, naming what moved — obeying a config file
silently is how a number nobody remembers setting ends up explaining a result
nobody expected. And the rules quote the limits **actually in force**, in the
report and in the audit trail: with a static table, a run under
`contacts_per_day: 1` refused an action and explained it with "at most two
messages to one party in a rolling day". `rule_says` is what an auditor reads
months later, so it has to be what happened.

The *basis* is not configurable. A project sets its threshold; it does not get
to edit the obligation the threshold answers to.

### The number

```
  at risk                 ₹36,54,915  the money these records represent
  recovered               ₹11,24,061  came back during the run
  would have anyway       -₹2,96,309  the same records recover this much untouc…
  ────────────────────────────────────
  attributable             ₹8,27,752  recovered because the agent acted
  spent                        -₹848  retries, messages and review time
  ────────────────────────────────────
  net                      ₹8,26,904  attributable less what it cost
```

With no agent at all, the same records return ₹4,99,092.

The counterfactual is computed **up front, on the same set**, so it cannot be
assembled afterwards from whatever looks best.

### The trail

Every decision — executed, blocked, *and skipped* — is an entry. "Considered and
left alone" has to be distinguishable from "never looked". Entries are
hash-chained; the head is signed with the same ed25519 key that signs compliance
reports. Altering, deleting, reordering and appending are all caught, and the
verifier names the entry:

```
FAILED  tampered.json
        entry 268 has been altered since it was written
```

It states what that proves and what it does not: the run is **simulated**, no
gateway was called, no message was sent. There is deliberately no `--execute`.

---

## 3. Reconciliation

Five tiers, because they are different claims and averaging them into one
percentage hides which is which:

| Tier | Claim |
|---|---|
| `exact` | reference and amount agree |
| `fee-aware` | the gap is commission + tax on it + TDS, **computed** not tolerated |
| `split` | one capture paid out in parts — including when one leg lost its reference |
| `grouped` | a day of settlement lines netting to one bank credit |
| `fuzzy` | no reference; amount and window agree — *probable*, for review, never closed |

Three numbers print together, because any one alone is game-able:

```
  matched           96.4%  █████████████████████████░  212 of 220 captures
  matched (₹)       92.0%  ████████████████████████░░  ₹5,80,270 of ₹6,30,887
  correct          100.0%  ██████████████████████████  225 of 225 pairings veri…
```

Real books have no answer key, and the report says so rather than inventing the
one number nobody could check.

**The exception list is the deliverable.** Each carries a reason and a next step,
and the expensive kind is named as such — captures the gateway never settled are
money it owes, and nothing in the settlement file points at them. Exit 1 when
anything is unexplained, so a nightly close can gate on it.

---

## Tuning the policy

```bash
sirus revenue watch batch
```

Re-runs when the batch or `sirus.yaml` changes, and prints **only what moved**:

```
 changed  sirus.yaml changed
    actions taken                  76 →            61   ▼ 15
    actions refused                36 →            39   ▲ 3
    attributable            ₹8,27,752 →     ₹8,20,677   ▼ ₹7,075
      contact_frequency            16 →            20   ▲ 4
```

That is what tightening `contacts_per_day` from 2 to 1 costs, stated rather than
inferred from two reports read one after the other. Refusals break out per rule,
because "you tightened the contact limit" should read as `contact_frequency`
rising, not as a change in an aggregate nobody can act on.

It writes nothing — the audit trail stays a return value, since a loop
re-running on every keystroke should not leave a hundred signed trails behind
it. `recover` and `watch` share one pipeline (`revenue/pipeline.ts`) so the two
cannot drift.

## Is it stable, and did that change help?

```bash
sirus revenue sweep --seeds 8 --save baseline.json
# ... change the model ...
sirus revenue sweep --seeds 8 --against baseline.json
```

One batch is an anecdote. The sweep runs the whole evaluation over
independently generated batches and prints **the rows, not just the mean** — a
mean edge of +1.0% built from eight agreeing batches is a different claim from
the same mean built from seven wins and one loss of three points, and only the rows say which
one you have.

```
  seed           precision   recall  recall ₹  vs heuristic  of ceiling  touched
  sirus-sweep-1      47.8%    23.9%     87.9%         +0.0%       91.4%        0
  sirus-sweep-2      35.8%    18.3%     80.5%         +3.0%       85.1%        0
  ...
  mean               45.1%    23.6%     82.6%         +1.0%       87.2%        0

  beat every capacity-matched heuristic on 7 of 8 batches · mean calibration gap
  5.7%
  over the same batches the heuristics touched 26 records nothing may touch;
  this touched 0
```

`--against` prints the deltas since a saved run, **including the ones that got
worse** — tightening capacity to 5%, for instance, buys +3.0pp of edge over the
heuristics and costs 16.9pp of recall, and the table says "2 better, 4 worse"
rather than leading with the improvement. Measures where lower is better are
marked as such.

It refuses to call two runs a comparison when they used different seeds or
different batch sizes. Subtracting two different experiments produces a number
that reads exactly like a result.

## Rehearsing it

```bash
pnpm rehearse:revenue
```

Drives the beat through the interactive shell in a real pty, checks that eight
things actually landed on screen, and prints how long each one takes. The
characteristic failure here is not a crash — it is fifty lines arriving in one
paint, which reads as a paste rather than an agent working, and which a green
test suite cannot see.

Everything on the demo path is paced for that reason: `detect` a record at a
time, `recover` a decision at a time, `reconcile` a block at a time. Roughly six
seconds of terminal time across the three, so the rest of the slot is narration.
`SIRUS_REVENUE_PACE` sets the per-line delay and `0` turns it off — as it is
automatically for `--json`, a pipe, and CI.

## The published page

```bash
pnpm artifact
```

`scripts/artifact/collect.mjs` runs the CLI against the two seeds and writes
every figure the page shows into `metrics.json`; `build.mjs` renders the HTML
from it. Nothing on the page is typed except the prose, and where the prose
makes a numeric claim it interpolates the same figure the table does, so the two
cannot drift.

Every figure is measured, including the test count — which used to be grepped
out of `AGENTS.md`, making it the one number on the page nobody had run to
obtain, and the one that went stale twice. The collector runs the suite now, and
refuses to collect at all from a build that does not pass: a page published from
a failing build describes something nobody can run.

`pnpm artifact:check` re-collects and diffs against the committed
`metrics.json`, naming every figure that moved and exiting 1 if any did.
Generating the page stops it being *typed* wrong; it does not stop it going
stale, and a model change with no regeneration publishes figures describing a
build nobody can run. It caught one on its first run — the page claimed 533
tests against a build with 546.

It exists because the first version was transcribed from a terminal and went
stale twice in a day — once when the risk-block hold changed the baselines, once
when the calibration wording changed. A number that has to be copied is a number
that will be wrong.

## Neither generator will quietly destroy evidence

A batch is what every figure reported against it rests on, and `truth.jsonl` is
the only thing that can score it again. `links.json` plays the same part for a
set of books: it is the file that says whether a match was *correct* rather than
merely confident.

Both generators used to overwrite silently. They refuse now — but only when the
regeneration would change what is there. The generators are deterministic, so
rewriting the same seed produces byte-identical files and stays idempotent for
scripts.

```
error: …/batch already holds a different batch.
  It was generated from seed "first" (1050 records, 2026-08-26), and its
  truth.jsonl is the only thing that can score it.
    Write it somewhere else:  sirus revenue gen <other-dir> --seed second
    Or replace it on purpose: --force
```

## What is synthetic, and what is not

Every batch and every set of books is generated from a seed, and the same seed
gives the same data on any machine. The rails (UPI, NACH, RuPay) and their
failure modes are real; **every gateway and bank named is invented**, because
generating outage records against a real company's name produces a document that
reads as a claim about that company.

Money is **integer paise** everywhere below the formatter. A reconciler that
needs a rupee of slack for floating point cannot detect a rupee of theft.

Nothing here is offence-capable. The ring detector's only output is a hold and a
queue for a human; the recovery agent's most-used capability is refusing to act.

---

## Bugs this found in itself

Kept because each is the kind of thing a green test suite hides:

- The detector retried a payment the **issuer had already refused on risk
  grounds**. Caught by the forbidden-touches column, not by a test.
- `human_review` cost ₹85 an action and was **exempt from the budget**, so a run
  capped at ₹50 spent ₹510 of analyst time.
- The generator made a **disputed record recoverable** when it fell inside a
  gateway outage — a fixture quietly disagreeing with the policy it existed to
  test.
- A chargeback fee was carried as **negative TDS**, which balanced the total and
  broke the identity every settlement line must satisfy.
- Duplicate bank postings were injected at 3% per line on a dozen lines, so most
  sets had none — a defect present on average and on no particular run.
